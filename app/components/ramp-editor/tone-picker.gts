import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { on } from "@ember/modifier";
import type { ToneAnchor } from "#utils/interpolate";
import type { ColourToken } from "#utils/token-generator";
import type { Tone } from "#utils/colours";
import { hexToOklch } from "#utils/colour-convert";
import HueWheel from "#components/hue-wheel/hue-wheel";
import styles from "./tone-picker.module.css";
import { or } from "#app/utils/helpers.ts";

interface Signature {
  Args: {
    tone: Tone;
    /** Existing anchor at this tone, if any */
    anchor: ToneAnchor | undefined;
    /** Current interpolated token at this tone */
    token: ColourToken | undefined;
    /** True for tones 50, 500, 950 -- shows reset instead of remove */
    isEndpoint: boolean;
    onChange: (values: { l: number; c: number; h: number }) => void;
    onRemove: () => void;
    onClose: () => void;
  };
}

export default class TonePicker extends Component<Signature> {
  @tracked hexInput = "";
  @tracked hexInvalid = false;

  // Use anchor values if anchored, otherwise the interpolated token values
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

  @action onHueChange(hue: number): void {
    this.args.onChange({ l: this.l, c: this.c, h: hue });
  }

  @action onLightnessInput(e: Event): void {
    const l = parseFloat((e.target as HTMLInputElement).value);
    this.args.onChange({ l, c: this.c, h: this.h });
  }

  @action onChromaInput(e: Event): void {
    const c = parseFloat((e.target as HTMLInputElement).value);
    this.args.onChange({ l: this.l, c, h: this.h });
  }

  @action onHueSlider(e: Event): void {
    const h = parseFloat((e.target as HTMLInputElement).value);
    this.args.onChange({ l: this.l, c: this.c, h });
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

        {{! L / C / H sliders }}
        <div class={{styles.slidersCol}}>
          <div class={{styles.fieldRow}}>
            <span class={{styles.label}}>H</span>
            <input
              class={{styles.slider}}
              type="range"
              min="0"
              max="360"
              step="0.5"
              value={{this.h}}
              {{on "input" this.onHueSlider}}
            />
            <span class={{styles.value}}>{{this.h}}°</span>
          </div>
          <div class={{styles.fieldRow}}>
            <span class={{styles.label}}>L</span>
            <input
              class={{styles.slider}}
              type="range"
              min="0"
              max="1"
              step="0.001"
              value={{this.l}}
              {{on "input" this.onLightnessInput}}
            />
            <span class={{styles.value}}>{{this.l}}</span>
          </div>
          <div class={{styles.fieldRow}}>
            <span class={{styles.label}}>C</span>
            <input
              class={{styles.slider}}
              type="range"
              min="0"
              max="0.4"
              step="0.001"
              value={{this.c}}
              {{on "input" this.onChromaInput}}
            />
            <span class={{styles.value}}>{{this.c}}</span>
          </div>
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
