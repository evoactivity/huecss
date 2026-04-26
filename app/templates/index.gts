import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { DEFAULT_COLOURS } from "#utils/colours";
import type { ColourDefinition } from "#utils/colours";
import type { ActiveColour, CurveOverride, GlobalCurves } from "#utils/token-generator";
import { generateTokens, DEFAULT_GLOBAL_CURVES } from "#utils/token-generator";
import { generateCss } from "#utils/css-output";
import type { BezierCurve } from "#utils/spline";
import ColourPicker from "#components/colour-picker/colour-picker";
import CustomColourForm from "#components/custom-colour-form/custom-colour-form";
import SplineEditor from "#components/spline-editor/spline-editor";
import ToneSwatches from "#components/tone-swatches/tone-swatches";
import CssOutput from "#components/css-output/css-output";

export default class IndexRoute extends Component {
  @tracked activeColours: ActiveColour[] = [];
  @tracked customColours: ColourDefinition[] = [];
  @tracked globalCurves: GlobalCurves = DEFAULT_GLOBAL_CURVES;

  get allColours(): ColourDefinition[] {
    return [...DEFAULT_COLOURS, ...this.customColours];
  }

  get existingNames(): string[] {
    return this.allColours.map((c) => c.name);
  }

  get tokens() {
    return generateTokens(this.activeColours, this.globalCurves);
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
      this.activeColours = [...this.activeColours, { definition: colour }];
    }
  }

  @action addCustomColour(colour: ColourDefinition): void {
    this.customColours = [...this.customColours, colour];
    this.activeColours = [...this.activeColours, { definition: colour }];
  }

  @action setCurveOverride(name: string, override: CurveOverride | undefined): void {
    this.activeColours = this.activeColours.map((a) =>
      a.definition.name === name ? { ...a, curveOverride: override } : a,
    );
  }

  @action setGlobalLightness(curve: BezierCurve): void {
    this.globalCurves = { ...this.globalCurves, lightness: curve };
  }

  @action setGlobalChroma(curve: BezierCurve): void {
    this.globalCurves = { ...this.globalCurves, chroma: curve };
  }

  <template>
    <main>
      <header>
        <h1>huecss</h1>
        <p>Generate oklch colour token ramps for your design system.</p>
      </header>

      <section aria-labelledby="colours-heading">
        <h2 id="colours-heading">Select colours</h2>
        <ColourPicker
          @colours={{this.allColours}}
          @activeColours={{this.activeColours}}
          @tokens={{this.tokens}}
          @onToggle={{this.toggleColour}}
          @onCurveOverride={{this.setCurveOverride}}
        />
        <details>
          <summary>Add a custom colour</summary>
          <CustomColourForm @existingNames={{this.existingNames}} @onAdd={{this.addCustomColour}} />
        </details>
      </section>

      <section aria-labelledby="curves-heading">
        <h2 id="curves-heading">Global curves</h2>
        <SplineEditor
          @label="Lightness"
          @curve={{this.globalCurves.lightness}}
          @tokens={{this.tokens}}
          @onChange={{this.setGlobalLightness}}
        />
        <SplineEditor
          @label="Chroma"
          @curve={{this.globalCurves.chroma}}
          @tokens={{this.tokens}}
          @onChange={{this.setGlobalChroma}}
        />
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
