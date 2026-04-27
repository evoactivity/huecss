import Component from "@glimmer/component";
import { service } from "@ember/service";
import { on } from "@ember/modifier";
import { fn } from "@ember/helper";
import type { ColourToken, ActiveColour } from "#utils/token-generator";
import type { ToneAnchor } from "#utils/interpolate";
import type { Tone } from "#utils/colours";
import { TONES } from "#utils/colours";
import { eq } from "#utils/helpers";
import { trackedObject } from "@ember/reactive/collections";
import DraggableModal from "#components/draggable-modal/draggable-modal";
import TonePicker from "#components/ramp-editor/tone-picker";
import { htmlSafe } from "@ember/template";
import type { SafeString } from "@ember/template";
import type ColourStudio from "#services/colour-studio";
import styles from "./ramp-editor.module.css";

interface Signature {
  Args: {
    active: ActiveColour;
    tokens: ColourToken[];
  };
}

export default class RampEditor extends Component<Signature> {
  @service("colour-studio") declare studio: ColourStudio;

  get colourName(): string {
    return this.args.active.definition.name;
  }

  get isOpen(): boolean {
    return (
      this.studio.openPicker.colourName === this.colourName && this.studio.openPicker.tone !== null
    );
  }

  get openTone(): Tone | null {
    return this.isOpen ? this.studio.openPicker.tone : null;
  }

  /**
   * Non-null openTone for use inside the {{#if this.isOpen}} branch in the
   * template, where the picker tone is guaranteed to be set. Glint cannot
   * narrow the getter automatically through the if check, so we expose a
   * separate accessor that asserts non-null.
   */
  get openToneRequired(): Tone {
    const tone = this.studio.openPicker.tone;
    if (tone === null) throw new Error("openToneRequired read while picker is closed");
    return tone;
  }

  get anchors(): ToneAnchor[] {
    return this.args.active.anchors;
  }

  anchorAt = (tone: Tone): ToneAnchor | undefined => this.anchors.find((a) => a.tone === tone);

  tokenAt = (tone: Tone): ColourToken | undefined => this.args.tokens.find((t) => t.tone === tone);

  swatchStyle = (tone: Tone): SafeString => {
    const token = this.tokenAt(tone);
    if (!token) return htmlSafe("background: #2e2e2e");
    return htmlSafe(`background: oklch(${token.l} ${token.c} ${token.h})`);
  };

  onSwatchClick = (tone: Tone, e: MouseEvent): void => {
    // Clicking the same tone on this row closes the picker
    if (
      this.studio.openPicker.colourName === this.colourName &&
      this.studio.openPicker.tone === tone
    ) {
      this.studio.closeTonePicker();
      return;
    }
    const rect = (e.currentTarget as HTMLElement).getBoundingClientRect();
    const modalWidth = 320;
    let x = rect.left + rect.width / 2 - modalWidth / 2;
    let y = rect.bottom + 8;
    x = Math.min(window.innerWidth - modalWidth - 8, Math.max(8, x));
    if (y + 400 > window.innerHeight) {
      y = rect.top - 8;
    }
    this.studio.openTonePicker(this.colourName, tone, { x, y });
  };

  onPickerChange = (tone: Tone, values: { l: number; c: number; h: number }): void => {
    const idx = this.anchors.findIndex((a) => a.tone === tone);
    if (idx !== -1) {
      Object.assign(this.anchors[idx]!, values);
    } else {
      const newAnchor: ToneAnchor = trackedObject({ tone, ...values });
      const insertAt = this.anchors.findIndex((a) => a.tone > tone);
      if (insertAt === -1) {
        this.anchors.push(newAnchor);
      } else {
        this.anchors.splice(insertAt, 0, newAnchor);
      }
    }
  };

  onLockTone = (tone: Tone): void => {
    const token = this.tokenAt(tone);
    if (!token) return;
    const newAnchor: ToneAnchor = trackedObject({ tone, l: token.l, c: token.c, h: token.h });
    const insertAt = this.anchors.findIndex((a) => a.tone > tone);
    if (insertAt === -1) {
      this.anchors.push(newAnchor);
    } else {
      this.anchors.splice(insertAt, 0, newAnchor);
    }
  };

  onRemoveAnchor = (tone: Tone): void => {
    const idx = this.anchors.findIndex((a) => a.tone === tone);
    if (idx !== -1) this.anchors.splice(idx, 1);
    this.studio.closeTonePicker();
  };

  <template>
    <div class={{styles.wrapper}}>
      {{#each TONES as |tone|}}
        {{#let (this.anchorAt tone) as |anchor|}}
          <div
            class="{{styles.toneSlot}}
              {{if anchor styles.anchored}}
              {{if (eq this.openTone tone) styles.active}}"
          >
            <button
              type="button"
              class={{styles.swatch}}
              style={{this.swatchStyle tone}}
              title="Tone {{tone}}{{if anchor ' (anchored)'}}"
              {{on "click" (fn this.onSwatchClick tone)}}
            ></button>
            <span class={{styles.toneLabel}}>{{tone}}</span>
          </div>
        {{/let}}
      {{/each}}

      {{#if this.isOpen}}
        <DraggableModal
          @title="Tone {{this.openToneRequired}}"
          @position={{this.studio.openPicker.position}}
          @onClose={{this.studio.closeTonePicker}}
        >
          <TonePicker
            @tone={{this.openToneRequired}}
            @anchor={{(this.anchorAt this.openToneRequired)}}
            @token={{(this.tokenAt this.openToneRequired)}}
            @onChange={{(fn this.onPickerChange this.openToneRequired)}}
            @onLock={{(fn this.onLockTone this.openToneRequired)}}
            @onRemove={{(fn this.onRemoveAnchor this.openToneRequired)}}
            @onClose={{this.studio.closeTonePicker}}
          />
        </DraggableModal>
      {{/if}}
    </div>
  </template>
}
