import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { on } from "@ember/modifier";
import { fn } from "@ember/helper";
import type { ColourDefinition } from "#utils/colours";
import type { CurveOverride, ActiveColour, ColourToken } from "#utils/token-generator";
import { DEFAULT_CHROMA_CURVE, DEFAULT_LIGHTNESS_CURVE, type BezierCurve } from "#utils/spline";
import { eq } from "#utils/helpers";
import SplineEditor from "#components/spline-editor/spline-editor";
import styles from "./colour-picker.module.css";

interface Signature {
  Args: {
    colours: ColourDefinition[];
    activeColours: ActiveColour[];
    tokens: ColourToken[];
    onToggle: (colour: ColourDefinition) => void;
    onCurveOverride: (name: string, override: CurveOverride | undefined) => void;
  };
}

export default class ColourPicker extends Component<Signature> {
  @tracked expandedName: string | null = null;

  isActive = (name: string): boolean => {
    return this.args.activeColours.some((a) => a.definition.name === name);
  };

  getOverride = (name: string): CurveOverride | undefined => {
    return this.args.activeColours.find((a) => a.definition.name === name)?.curveOverride;
  };

  tokensFor = (name: string): ColourToken[] => {
    return this.args.tokens.filter((t) => t.name === name);
  };

  getDefinition = (name: string): ColourDefinition | undefined => {
    return this.args.colours.find((c) => c.name === name);
  };

  // Returns the user override if present, otherwise the colour's own fitted curve.
  // SplineEditor treats undefined as "use the global default", so we must always
  // provide the colour-specific curve when available.
  getLightnessCurve = (name: string): BezierCurve | undefined => {
    return this.getOverride(name)?.lightness ?? this.getDefinition(name)?.lightnessCurve;
  };

  getChromaCurve = (name: string): BezierCurve | undefined => {
    return this.getOverride(name)?.chroma ?? this.getDefinition(name)?.chromaCurve;
  };

  swatchStyle = (colour: ColourDefinition): string => {
    return `background: oklch(${colour.lightness} ${colour.chroma} ${colour.hue})`;
  };

  @action toggleExpand(name: string): void {
    this.expandedName = this.expandedName === name ? null : name;
  }

  @action handleToggle(colour: ColourDefinition): void {
    if (this.isActive(colour.name)) {
      this.expandedName = null;
    }
    this.args.onToggle(colour);
  }

  @action handleLightnessChange(name: string, curve: BezierCurve): void {
    const existing = this.getOverride(name);
    this.args.onCurveOverride(name, { ...existing, lightness: curve });
  }

  @action handleChromaChange(name: string, curve: BezierCurve): void {
    const existing = this.getOverride(name);
    this.args.onCurveOverride(name, { ...existing, chroma: curve });
  }

  @action resetOverride(name: string): void {
    this.args.onCurveOverride(name, undefined);
  }

  <template>
    <div class={{styles.grid}}>
      {{#each @colours as |colour|}}
        <button
          type="button"
          class="{{styles.swatch}} {{if (this.isActive colour.name) styles.selected}}"
          title={{colour.name}}
          {{on "click" (fn this.handleToggle colour)}}
        >
          <span class={{styles.swatchColour}} style={{this.swatchStyle colour}}></span>
          <span class={{styles.label}}>{{colour.name}}</span>
        </button>

        {{#if (this.isActive colour.name)}}
          {{#if (eq this.expandedName colour.name)}}
            <div class={{styles.expandedColour}}>
              <div class={{styles.expandedHeader}}>
                <strong>{{colour.name}} curves</strong>
                {{#if (this.getOverride colour.name)}}
                  <button
                    type="button"
                    class={{styles.resetButton}}
                    {{on "click" (fn this.resetOverride colour.name)}}
                  >
                    Reset to global
                  </button>
                {{/if}}
              </div>
              <SplineEditor
                @label="Lightness"
                @curve={{(this.getLightnessCurve colour.name)}}
                @defaultCurve={{DEFAULT_LIGHTNESS_CURVE}}
                @tokens={{(this.tokensFor colour.name)}}
                @onChange={{(fn this.handleLightnessChange colour.name)}}
              />
              <SplineEditor
                @label="Chroma"
                @curve={{(this.getChromaCurve colour.name)}}
                @defaultCurve={{DEFAULT_CHROMA_CURVE}}
                @tokens={{(this.tokensFor colour.name)}}
                @onChange={{(fn this.handleChromaChange colour.name)}}
              />
            </div>
          {{else}}
            <button
              type="button"
              class={{styles.swatch}}
              {{on "click" (fn this.toggleExpand colour.name)}}
            >
              Edit curves
            </button>
          {{/if}}
        {{/if}}
      {{/each}}
    </div>
  </template>
}
