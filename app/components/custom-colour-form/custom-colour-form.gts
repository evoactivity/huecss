import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { on } from "@ember/modifier";
import { not } from "#utils/helpers";
import type { ColourDefinition } from "#utils/colours";
import { hexToOklch } from "#utils/colour-convert";
import HueWheel from "#components/hue-wheel/hue-wheel";
import GradientSlider from "#components/gradient-slider/gradient-slider";
import styles from "./custom-colour-form.module.css";

interface Signature {
  Args: {
    existingNames: string[];
    onAdd: (colour: ColourDefinition) => void;
  };
}

export default class CustomColourForm extends Component<Signature> {
  @tracked name = "";
  @tracked hue = 0;
  @tracked lightness = 0.55;
  @tracked chroma = 0.15;
  @tracked hexInput = "";
  @tracked hexError = false;

  get previewColour(): string {
    return `oklch(${this.lightness} ${this.chroma} ${this.hue})`;
  }

  // Lightness gradient: black → current colour → white, keeping C and H fixed.
  // Using 5 stops so the curve through oklch space is well-sampled.
  get lightnessGradient(): string {
    const { chroma: c, hue: h } = this;
    return [
      "linear-gradient(to right in oklch,",
      `oklch(0 ${c} ${h}),`,
      `oklch(0.25 ${c} ${h}),`,
      `oklch(0.5 ${c} ${h}),`,
      `oklch(0.75 ${c} ${h}),`,
      `oklch(1 ${c} ${h}))`,
    ].join(" ");
  }

  // Chroma gradient: gray (C=0) → full saturation (C=0.4), keeping L and H fixed.
  get chromaGradient(): string {
    const { lightness: l, hue: h } = this;
    return [
      "linear-gradient(to right in oklch,",
      `oklch(${l} 0 ${h}),`,
      `oklch(${l} 0.1 ${h}),`,
      `oklch(${l} 0.2 ${h}),`,
      `oklch(${l} 0.3 ${h}),`,
      `oklch(${l} 0.4 ${h}))`,
    ].join(" ");
  }

  get lightnessThumb(): string {
    return `oklch(${this.lightness} ${this.chroma} ${this.hue})`;
  }

  get chromaThumb(): string {
    return `oklch(${this.lightness} ${this.chroma} ${this.hue})`;
  }

  get lightnessDisplay(): string {
    return this.lightness.toFixed(3);
  }

  get chromaDisplay(): string {
    return this.chroma.toFixed(3);
  }

  get nameError(): string | null {
    const trimmed = this.name.trim();
    if (!trimmed) return null;
    if (!/^[a-z][a-z0-9-]*$/.test(trimmed)) {
      return "Lowercase letters, numbers, hyphens. Must start with a letter.";
    }
    if (this.args.existingNames.includes(trimmed)) {
      return "A colour with this name already exists.";
    }
    return null;
  }

  get canSubmit(): boolean {
    return this.name.trim().length > 0 && this.nameError === null;
  }

  @action onHueChange(hue: number): void {
    this.hue = hue;
  }

  @action onLightnessChange(value: number): void {
    this.lightness = value;
  }

  @action onChromaChange(value: number): void {
    this.chroma = value;
  }

  @action onHexInput(e: Event): void {
    const raw = (e.target as HTMLInputElement).value.trim();
    this.hexInput = raw;
    if (!raw) {
      this.hexError = false;
      return;
    }
    const oklch = hexToOklch(raw);
    if (oklch) {
      this.hue = Math.round(oklch.h * 10) / 10;
      this.lightness = Math.round(oklch.l * 1000) / 1000;
      this.chroma = Math.round(oklch.c * 1000) / 1000;
      this.hexError = false;
    } else {
      this.hexError = true;
    }
  }

  @action onNameInput(e: Event): void {
    this.name = (e.target as HTMLInputElement).value;
  }

  @action handleSubmit(e: Event): void {
    e.preventDefault();
    if (!this.canSubmit) return;
    this.args.onAdd({
      name: this.name.trim(),
      hue: this.hue,
      lightness: this.lightness,
      chroma: this.chroma,
    });
    this.name = "";
    this.hue = 0;
    this.lightness = 0.55;
    this.chroma = 0.15;
    this.hexInput = "";
  }

  <template>
    <form class={{styles.form}} {{on "submit" this.handleSubmit}}>

      {{! Hex paste }}
      <div class={{styles.hexRow}}>
        <input
          class="{{styles.hexInput}} {{if this.hexError styles.error}}"
          type="text"
          placeholder="#hex"
          value={{this.hexInput}}
          {{on "input" this.onHexInput}}
        />
        <div class={{styles.hexSwatch}} style="background: {{this.previewColour}}"></div>
      </div>

      <div class={{styles.row}}>
        {{! Hue wheel }}
        <div class={{styles.wheelCol}}>
          <HueWheel
            @hue={{this.hue}}
            @lightness={{this.lightness}}
            @chroma={{this.chroma}}
            @onChange={{this.onHueChange}}
          />
        </div>

        {{! L and C gradient sliders }}
        <div class={{styles.slidersCol}}>
          <GradientSlider
            @label="Lightness"
            @min={{0}}
            @max={{1}}
            @step={{0.001}}
            @value={{this.lightness}}
            @gradient={{this.lightnessGradient}}
            @thumbColour={{this.lightnessThumb}}
            @displayValue={{this.lightnessDisplay}}
            @onChange={{this.onLightnessChange}}
          />
          <GradientSlider
            @label="Chroma"
            @min={{0}}
            @max={{0.4}}
            @step={{0.001}}
            @value={{this.chroma}}
            @gradient={{this.chromaGradient}}
            @thumbColour={{this.chromaThumb}}
            @displayValue={{this.chromaDisplay}}
            @onChange={{this.onChromaChange}}
          />
        </div>
      </div>

      {{! Name and add }}
      <div class={{styles.nameRow}}>
        <div class={{styles.field}} style="flex: 1">
          <input
            id="custom-colour-name"
            class={{styles.nameInput}}
            type="text"
            placeholder="Colour name (e.g. brand)"
            value={{this.name}}
            {{on "input" this.onNameInput}}
          />
          {{#if this.nameError}}
            <span class={{styles.error}}>{{this.nameError}}</span>
          {{/if}}
        </div>
        <button type="submit" class={{styles.addButton}} disabled={{not this.canSubmit}}>
          Add colour
        </button>
      </div>
    </form>
  </template>
}
