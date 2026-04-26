import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { on } from "@ember/modifier";
import { DEFAULT_COLOURS } from "#utils/colours";
import type { ColourDefinition } from "#utils/colours";
import type { ActiveColour, ColourToken, CurveOverride } from "#utils/token-generator";
import {
  generateTokens,
  activateColour,
  DEFAULT_GLOBAL_CURVES,
  DEFAULT_INTERPOLATION_MODE,
} from "#utils/token-generator";
import type { InterpolationMode, ToneAnchor } from "#utils/interpolate";
import { INTERPOLATION_MODES } from "#utils/interpolate";
import { generateCss } from "#utils/css-output";
import ColourPicker from "#components/colour-picker/colour-picker";
import CustomColourForm from "#components/custom-colour-form/custom-colour-form";
import ToneSwatches from "#components/tone-swatches/tone-swatches";
import CssOutput from "#components/css-output/css-output";
import { eq } from "#app/utils/helpers.ts";

export default class IndexRoute extends Component {
  @tracked activeColours: ActiveColour[] = [];
  @tracked customColours: ColourDefinition[] = [];
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

  @action toggleColour(colour: ColourDefinition): void {
    const exists = this.activeColours.find((a) => a.definition.name === colour.name);
    if (exists) {
      this.activeColours = this.activeColours.filter((a) => a.definition.name !== colour.name);
    } else {
      this.activeColours = [
        ...this.activeColours,
        activateColour(colour, DEFAULT_GLOBAL_CURVES, this.interpolationMode),
      ];
    }
  }

  @action addCustomColour(colour: ColourDefinition): void {
    this.customColours = [...this.customColours, colour];
    this.activeColours = [
      ...this.activeColours,
      activateColour(colour, DEFAULT_GLOBAL_CURVES, this.interpolationMode),
    ];
  }

  @action setInterpolationMode(e: Event): void {
    const mode = (e.target as HTMLSelectElement).value as InterpolationMode;
    this.interpolationMode = mode;
    // Update all active colours to use the new mode
    this.activeColours = this.activeColours.map((a) => ({ ...a, interpolationMode: mode }));
  }

  @action setAnchors(name: string, anchors: ToneAnchor[]): void {
    this.activeColours = this.activeColours.map((a) =>
      a.definition.name === name ? { ...a, anchors } : a,
    );
  }

  @action setCurveOverride(name: string, override: CurveOverride | undefined): void {
    this.activeColours = this.activeColours.map((a) =>
      a.definition.name === name ? { ...a, curveOverride: override } : a,
    );
  }

  <template>
    <main>
      <header>
        <h1>huecss</h1>
        <p>Generate oklch colour token ramps for your design system.</p>
      </header>

      <section aria-labelledby="colours-heading">
        <h2 id="colours-heading">Select colours</h2>
        <div>
          <label for="interp-mode">Interpolation mode</label>
          <select id="interp-mode" {{on "change" this.setInterpolationMode}}>
            {{#each INTERPOLATION_MODES as |mode|}}
              <option value={{mode}} selected={{eq mode this.interpolationMode}}>{{mode}}</option>
            {{/each}}
          </select>
        </div>
        <ColourPicker
          @colours={{this.allColours}}
          @activeColours={{this.activeColours}}
          @tokens={{this.tokens}}
          @onToggle={{this.toggleColour}}
          @onSetAnchors={{this.setAnchors}}
          @onCurveOverride={{this.setCurveOverride}}
        />
        <details>
          <summary>Add a custom colour</summary>
          <CustomColourForm @existingNames={{this.existingNames}} @onAdd={{this.addCustomColour}} />
        </details>
      </section>

      {{#if this.hasActiveColours}}
        <section aria-labelledby="preview-heading">
          <h2 id="preview-heading">Tone preview</h2>
          <ToneSwatches @tokens={{this.tokens}} />
        </section>

        <section aria-labelledby="output-heading">
          <h2 id="output-heading">CSS output</h2>
          <CssOutput @css={{this.css}} />
        </section>
      {{else}}
        <p>Select at least one colour above to see the preview and output.</p>
      {{/if}}
    </main>
  </template>
}
