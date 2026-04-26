import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { on } from "@ember/modifier";
import { fn } from "@ember/helper";
import type { ColourToken, ActiveColour } from "#utils/token-generator";
import { effectiveCurves, DEFAULT_GLOBAL_CURVES } from "#utils/token-generator";
import type { ToneAnchor } from "#utils/interpolate";
import { revertAnchor } from "#utils/interpolate";
import type { Tone } from "#utils/colours";
import { TONES } from "#utils/colours";
import TonePicker from "#components/ramp-editor/tone-picker";
import { eq, or } from "#utils/helpers";
import styles from "./ramp-editor.module.css";

interface Signature {
  Args: {
    active: ActiveColour;
    tokens: ColourToken[];
    onSetAnchors: (anchors: ToneAnchor[]) => void;
  };
}

export default class RampEditor extends Component<Signature> {
  /** Tone whose picker is currently open, or null */
  @tracked openTone: Tone | null = null;

  get anchors(): ToneAnchor[] {
    return this.args.active.anchors;
  }

  anchorAt = (tone: Tone): ToneAnchor | undefined => {
    return this.anchors.find((a) => a.tone === tone);
  };

  tokenAt = (tone: Tone): ColourToken | undefined => {
    return this.args.tokens.find((t) => t.tone === tone);
  };

  swatchStyle = (tone: Tone): string => {
    const token = this.tokenAt(tone);
    if (!token) return "";
    return `background: oklch(${token.l} ${token.c} ${token.h})`;
  };

  @action onSwatchClick(tone: Tone): void {
    // Toggle picker: close if already open for this tone, open otherwise
    this.openTone = this.openTone === tone ? null : tone;
  }

  @action onPickerChange(tone: Tone, values: { l: number; c: number; h: number }): void {
    const existing = this.anchorAt(tone);
    if (existing) {
      // Update existing anchor
      this.args.onSetAnchors(
        this.anchors.map((a) => (a.tone === tone ? { ...a, ...values, seeded: false } : a)),
      );
    } else {
      // Add new anchor, keep sorted
      const newAnchor: ToneAnchor = { tone, ...values, seeded: false };
      const sorted = [...this.anchors, newAnchor].sort((a, b) => a.tone - b.tone);
      this.args.onSetAnchors(sorted);
    }
  }

  @action onRemoveAnchor(tone: Tone): void {
    const isEndpoint = tone === 50 || tone === 950 || tone === 500;

    if (isEndpoint) {
      // Revert to default rather than remove
      const { lightness, chroma } = effectiveCurves(this.args.active, DEFAULT_GLOBAL_CURVES);
      const reverted = revertAnchor(tone, this.args.active.definition, lightness, chroma);
      this.args.onSetAnchors(this.anchors.map((a) => (a.tone === tone ? reverted : a)));
    } else {
      // Remove user anchor entirely
      this.args.onSetAnchors(this.anchors.filter((a) => a.tone !== tone));
    }

    this.openTone = null;
  }

  @action onPickerClose(): void {
    this.openTone = null;
  }

  <template>
    <div class={{styles.wrapper}}>
      <div class={{styles.row}}>
        {{#each TONES as |tone|}}
          {{#let (this.anchorAt tone) as |anchor|}}
            <div class={{styles.toneSlot}}>
              {{! Anchor marker dot -- always shown for seeded anchors, filled differently for user anchors }}
              {{#if anchor}}
                <div
                  class="{{styles.anchorMarker}} {{if anchor.seeded styles.anchorMarkerSeeded}}"
                ></div>
              {{else}}
                <div style="height: 8px"></div>
              {{/if}}

              <button
                type="button"
                class="{{styles.swatch}} {{if (eq this.openTone tone) styles.swatchActive}}"
                style={{this.swatchStyle tone}}
                title="Tone {{tone}}{{if anchor ' (anchored)'}}"
                {{on "click" (fn this.onSwatchClick tone)}}
              ></button>

              <span class={{styles.toneLabel}}>{{tone}}</span>
            </div>
          {{/let}}
        {{/each}}
      </div>

      {{#if this.openTone}}
        {{#let (this.anchorAt this.openTone) as |anchor|}}
          <div class={{styles.pickerContainer}}>
            <TonePicker
              @tone={{this.openTone}}
              @anchor={{anchor}}
              @token={{(this.tokenAt this.openTone)}}
              @isEndpoint={{or (eq this.openTone 50) (eq this.openTone 500) (eq this.openTone 950)}}
              @onChange={{(fn this.onPickerChange this.openTone)}}
              @onRemove={{(fn this.onRemoveAnchor this.openTone)}}
              @onClose={{this.onPickerClose}}
            />
          </div>
        {{/let}}
      {{/if}}
    </div>
  </template>
}
