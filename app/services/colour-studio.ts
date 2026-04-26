import Service from "@ember/service";
import { tracked } from "@glimmer/tracking";
import { trackedArray } from "@ember/reactive/collections";
import { DEFAULT_COLOURS } from "#utils/colours";
import type { ColourDefinition } from "#utils/colours";
import type { ActiveColour, ColourToken, CurveOverride } from "#utils/token-generator";
import {
  generateTokens,
  activateColour,
  DEFAULT_GLOBAL_CURVES,
  DEFAULT_INTERPOLATION_MODE,
} from "#utils/token-generator";
import type { InterpolationMode } from "#utils/interpolate";
import { generateCss } from "#utils/css-output";

export default class ColourStudio extends Service {
  activeColours = trackedArray<ActiveColour>();
  customColours = trackedArray<ColourDefinition>();
  @tracked interpolationMode: InterpolationMode = DEFAULT_INTERPOLATION_MODE;

  get allColours(): ColourDefinition[] {
    return [...DEFAULT_COLOURS, ...this.customColours];
  }

  get existingNames(): string[] {
    return this.allColours.map((c) => c.name);
  }

  get tokens(): ColourToken[] {
    return generateTokens(this.activeColours);
  }

  get css(): string {
    return generateCss(this.tokens);
  }

  get hasActiveColours(): boolean {
    return this.activeColours.length > 0;
  }

  tokensFor = (name: string): ColourToken[] => {
    return this.tokens.filter((t) => t.name === name);
  };

  toggleColour = (colour: ColourDefinition): void => {
    const idx = this.activeColours.findIndex((a) => a.definition.name === colour.name);
    if (idx !== -1) {
      this.activeColours.splice(idx, 1);
    } else {
      this.activeColours.push(
        activateColour(colour, DEFAULT_GLOBAL_CURVES, this.interpolationMode),
      );
    }
  };

  addCustomColour = (colour: ColourDefinition): void => {
    this.customColours.push(colour);
    this.activeColours.push(activateColour(colour, DEFAULT_GLOBAL_CURVES, this.interpolationMode));
  };

  setInterpolationMode = (mode: InterpolationMode): void => {
    this.interpolationMode = mode;
    for (const active of this.activeColours) {
      active.interpolationMode = mode;
    }
  };

  setCurveOverride = (name: string, override: CurveOverride | undefined): void => {
    const target = this.activeColours.find((a) => a.definition.name === name);
    if (target) {
      target.curveOverride = override;
    }
  };
}
