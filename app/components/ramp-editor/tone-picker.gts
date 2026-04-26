import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { on } from "@ember/modifier";
import type { ToneAnchor } from "#utils/interpolate";
import type { ColourToken } from "#utils/token-generator";
import type { Tone } from "#utils/colours";
import { hexToOklch } from "#utils/colour-convert";
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
  @tracked hexInput = "";
  @tracked hexInvalid = false;

  get l(): number {
    return this.args.anchor?.l ?? this.args.token?.l ?? 0.5;
  }
  get c(): number {
    return this.args.anchor?.c ?? this.args.token?.c ?? 0.1;
  }
  get h(): number {
    return this.args.anchor?.h ?? this.args.token?.h ?? 0;
  }

  get previewStyle(): string {
    return `background: oklch(${this.l} ${this.c} ${this.h})`;
  }

  get removeLabel(): string {
    return this.args.isEndpoint ? "Reset to default" : "Remove anchor";
  }

  get isAnchored(): boolean {
    return this.args.anchor !== undefined;
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
    return this.l.toFixed(3);
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

  @action onHexInput(e: Event): void {
    const raw = (e.target as HTMLInputElement).value.trim();
    this.hexInput = raw;
    if (!raw) {
      this.hexInvalid = false;
      return;
    }
    const oklch = hexToOklch(raw);
    if (oklch) {
      this.hexInvalid = false;
      this.args.onChange(oklch);
    } else {
      this.hexInvalid = true;
    }
  }

  <template>
    <div class={{styles.picker}}>
      <div class={{styles.header}}>
        <span class={{styles.title}}>Tone {{@tone}}</span>
        <button type="button" class={{styles.closeButton}} {{on "click" @onClose}}>
          Close
        </button>
      </div>

      {{! Hex input }}
      <div class={{styles.hexRow}}>
        <input
          class="{{styles.hexInput}} {{if this.hexInvalid styles.invalid}}"
          type="text"
          placeholder="#hex"
          value={{this.hexInput}}
          {{on "input" this.onHexInput}}
        />
        <div class={{styles.preview}} style={{this.previewStyle}}></div>
      </div>

      <div class={{styles.row}}>
        {{! Hue wheel }}
        <div class={{styles.wheelCol}}>
          <HueWheel
            @hue={{this.h}}
            @lightness={{this.l}}
            @chroma={{this.c}}
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

      {{! Actions }}
      <div class={{styles.actions}}>
        {{#if (or this.isAnchored @isEndpoint)}}
          <button type="button" class={{styles.removeButton}} {{on "click" @onRemove}}>
            {{this.removeLabel}}
          </button>
        {{/if}}
      </div>
    </div>
  </template>
}
