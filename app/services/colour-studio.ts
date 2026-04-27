import Service from "@ember/service";
import { tracked } from "@glimmer/tracking";
import { trackedArray } from "@ember/reactive/collections";
import type { ModalPosition } from "#components/draggable-modal/draggable-modal";
import type { Tone } from "#utils/colours";
import { DEFAULT_COLOURS } from "#utils/colours";
import type { ColourDefinition } from "#utils/colours";
import type { ActiveColour, ColourToken, CurveOverride } from "#utils/token-generator";
import { generateTokens, activateColour } from "#utils/token-generator";

class TonePickerState {
  @tracked colourName: string | null = null;
  @tracked tone: Tone | null = null;
  @tracked position: ModalPosition = { x: 0, y: 0 };
}

export default class ColourStudio extends Service {
  activeColours = trackedArray<ActiveColour>();
  customColours = trackedArray<ColourDefinition>();

  // Global picker state, only one tone picker open at a time across all ramps.
  openPicker = new TonePickerState();

  openTonePicker = (colourName: string, tone: Tone, position: ModalPosition): void => {
    this.openPicker.colourName = colourName;
    this.openPicker.tone = tone;
    this.openPicker.position = position;
  };

  closeTonePicker = (): void => {
    this.openPicker.colourName = null;
    this.openPicker.tone = null;
  };

  get allColours(): ColourDefinition[] {
    return [...DEFAULT_COLOURS, ...this.customColours];
  }

  get existingNames(): string[] {
    return this.allColours.map((c) => c.name);
  }

  get tokens(): ColourToken[] {
    return generateTokens(this.activeColours);
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
      this.activeColours.push(activateColour(colour));
    }
  };

  addCustomColour = (colour: ColourDefinition): void => {
    this.customColours.push(colour);
    this.activeColours.push(activateColour(colour));
  };

  setCurveOverride = (name: string, override: CurveOverride | undefined): void => {
    const target = this.activeColours.find((a) => a.definition.name === name);
    if (target) {
      target.curveOverride = override;
    }
  };
}
