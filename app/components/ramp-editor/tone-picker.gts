import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { on } from "@ember/modifier";
import type { ToneAnchor } from "#utils/interpolate";
import type { ColourToken } from "#utils/token-generator";
import type { Tone } from "#utils/colours";
import { cssColourToOklch } from "#utils/colour-convert";
import { or } from "#utils/helpers";
import HueWheel from "#components/hue-wheel/hue-wheel";
import GradientSlider from "#components/gradient-slider/gradient-slider";
import styles from "./tone-picker.module.css";

interface Signature {
  Args: {
    tone: Tone;
    anchor: ToneAnchor | undefined;
    token: ColourToken | undefined;
    isEndpoint: boolean;
    onChange: (values: { l: number; c: number; h: number }) => void;
    onRemove: () => void;
    onClose: () => void;
  };
}

export default class TonePicker extends Component<Signature> {
  @tracked colourInput = "";
  @tracked colourInvalid = false;
  @tracked inputFocused = false;

  get l(): number {
    return this.args.anchor?.l ?? this.args.token?.l ?? 0.5;
  }
  get c(): number {
    return this.args.anchor?.c ?? this.args.token?.c ?? 0.1;
  }
  get h(): number {
    return this.args.anchor?.h ?? this.args.token?.h ?? 0;
  }

  // Shown in the input when not focused -- reflects the current l/c/h
  get colourString(): string {
    const l = Math.round(this.l * 10000) / 100;
    const c = Math.round(this.c * 10000) / 10000;
    const h = Math.round(this.h * 10) / 10;
    return `oklch(${l}% ${c} ${h})`;
  }

  get inputValue(): string {
    return this.inputFocused ? this.colourInput : this.colourString;
  }

  get isAnchored(): boolean {
    return this.args.anchor !== undefined;
  }
  get removeLabel(): string {
    return this.args.isEndpoint ? "Reset to default" : "Remove anchor";
  }

  get lightnessGradient(): string {
    const { c, h } = this;
    return `linear-gradient(to right in oklch, oklch(0 ${c} ${h}), oklch(0.25 ${c} ${h}), oklch(0.5 ${c} ${h}), oklch(0.75 ${c} ${h}), oklch(1 ${c} ${h}))`;
  }

  get chromaGradient(): string {
    const { l, h } = this;
    return `linear-gradient(to right in oklch, oklch(${l} 0 ${h}), oklch(${l} 0.1 ${h}), oklch(${l} 0.2 ${h}), oklch(${l} 0.3 ${h}), oklch(${l} 0.4 ${h}))`;
  }

  get thumbColour(): string {
    return `oklch(${this.l} ${this.c} ${this.h})`;
  }
  get lDisplay(): string {
    return `${(this.l * 100).toFixed(1)}%`;
  }
  get cDisplay(): string {
    return this.c.toFixed(3);
  }

  @action onHueChange(hue: number): void {
    this.args.onChange({ l: this.l, c: this.c, h: hue });
  }
  @action onLightnessChange(l: number): void {
    this.args.onChange({ l, c: this.c, h: this.h });
  }
  @action onChromaChange(c: number): void {
    this.args.onChange({ l: this.l, c, h: this.h });
  }

  @action onColourFocus(): void {
    this.inputFocused = true;
    this.colourInput = this.colourString;
    this.colourInvalid = false;
  }

  @action onColourBlur(): void {
    this.inputFocused = false;
    this.colourInvalid = false;
  }

  @action onColourInput(e: Event): void {
    const raw = (e.target as HTMLInputElement).value;
    this.colourInput = raw;
    if (!raw.trim()) {
      this.colourInvalid = false;
      return;
    }
    const oklch = cssColourToOklch(raw.trim());
    if (oklch) {
      this.colourInvalid = false;
      this.args.onChange(oklch);
    } else {
      this.colourInvalid = true;
    }
  }

  <template>
    <div class={{styles.picker}}>
      <div class={{styles.row}}>
        <div class={{styles.wheelCol}}>
          <HueWheel
            @hue={{this.h}}
            @lightness={{this.l}}
            @chroma={{this.c}}
            @onChange={{this.onHueChange}}
          />
        </div>
        <div class={{styles.slidersCol}}>
          <GradientSlider
            @label="Lightness"
            @min={{0}}
            @max={{1}}
            @step={{0.001}}
            @value={{this.l}}
            @gradient={{this.lightnessGradient}}
            @thumbColour={{this.thumbColour}}
            @displayValue={{this.lDisplay}}
            @onChange={{this.onLightnessChange}}
          />
          <GradientSlider
            @label="Chroma"
            @min={{0}}
            @max={{0.4}}
            @step={{0.001}}
            @value={{this.c}}
            @gradient={{this.chromaGradient}}
            @thumbColour={{this.thumbColour}}
            @displayValue={{this.cDisplay}}
            @onChange={{this.onChromaChange}}
          />
        </div>
      </div>

      <input
        class="{{styles.colourInput}} {{if this.colourInvalid styles.invalid}}"
        type="text"
        placeholder="oklch(…) / #hex / rgb(…)"
        value={{this.inputValue}}
        {{on "focus" this.onColourFocus}}
        {{on "blur" this.onColourBlur}}
        {{on "input" this.onColourInput}}
      />

      {{#if (or this.isAnchored @isEndpoint)}}
        <div class={{styles.actions}}>
          <button type="button" class={{styles.removeButton}} {{on "click" @onRemove}}>
            {{this.removeLabel}}
          </button>
        </div>
      {{/if}}
    </div>
  </template>
}
