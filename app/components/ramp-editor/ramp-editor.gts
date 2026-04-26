import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { on } from "@ember/modifier";
import { fn } from "@ember/helper";
import type { ColourToken, ActiveColour } from "#utils/token-generator";
import { effectiveCurves, DEFAULT_GLOBAL_CURVES } from "#utils/token-generator";
import type { ToneAnchor } from "#utils/interpolate";
import { revertAnchor } from "#utils/interpolate";
import type { Tone } from "#utils/colours";
import { TONES } from "#utils/colours";
import { eq, or, and, not } from "#utils/helpers";
import { trackedObject } from "@ember/reactive/collections";
import DraggableModal from "#components/draggable-modal/draggable-modal";
import type { ModalPosition } from "#components/draggable-modal/draggable-modal";
import TonePicker from "#components/ramp-editor/tone-picker";
import { htmlSafe } from "@ember/template";
import type { SafeString } from "@ember/template";
import styles from "./ramp-editor.module.css";

interface Signature {
  Args: {
    active: ActiveColour;
    tokens: ColourToken[];
  };
}

export default class RampEditor extends Component<Signature> {
  @tracked openTone: Tone | null = null;
  @tracked modalPosition: ModalPosition = { x: 0, y: 0 };

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
    if (this.openTone === tone) {
      this.openTone = null;
      return;
    }
    // Position modal below (and horizontally centred on) the clicked swatch
    const rect = (e.currentTarget as HTMLElement).getBoundingClientRect();
    const modalWidth = 320;
    let x = rect.left + rect.width / 2 - modalWidth / 2;
    let y = rect.bottom + 8;
    // Clamp to viewport
    x = Math.min(window.innerWidth - modalWidth - 8, Math.max(8, x));
    if (y + 400 > window.innerHeight) {
      y = rect.top - 8; // open above if near bottom
    }
    this.modalPosition = { x, y };
    this.openTone = tone;
  };

  onPickerChange = (tone: Tone, values: { l: number; c: number; h: number }): void => {
    const idx = this.anchors.findIndex((a) => a.tone === tone);
    if (idx !== -1) {
      Object.assign(this.anchors[idx]!, values);
      this.anchors[idx]!.seeded = false;
    } else {
      const newAnchor: ToneAnchor = trackedObject({ tone, ...values, seeded: false });
      const insertAt = this.anchors.findIndex((a) => a.tone > tone);
      if (insertAt === -1) {
        this.anchors.push(newAnchor);
      } else {
        this.anchors.splice(insertAt, 0, newAnchor);
      }
    }
  };

  onRemoveAnchor = (tone: Tone): void => {
    const isEndpoint = tone === 50 || tone === 950 || tone === 500;
    if (isEndpoint) {
      const { lightness, chroma } = effectiveCurves(this.args.active, DEFAULT_GLOBAL_CURVES);
      const reverted = revertAnchor(tone, this.args.active.definition, lightness, chroma);
      const idx = this.anchors.findIndex((a) => a.tone === tone);
      if (idx !== -1) Object.assign(this.anchors[idx]!, reverted);
    } else {
      const idx = this.anchors.findIndex((a) => a.tone === tone);
      if (idx !== -1) this.anchors.splice(idx, 1);
    }
    this.openTone = null;
  };

  onModalClose = (): void => {
    this.openTone = null;
  };

  <template>
    <div class={{styles.wrapper}}>
      <div class={{styles.row}}>
        {{#each TONES as |tone|}}
          {{#let (this.anchorAt tone) as |anchor|}}
            <div class={{styles.toneSlot}}>
              <div class={{styles.dotRow}}>
                {{#if anchor}}
                  <div
                    class="{{styles.dot}} {{if anchor.seeded styles.dotSeeded styles.dotUser}}"
                  ></div>
                {{else}}
                  <div class={{styles.dotEmpty}}></div>
                {{/if}}
              </div>
              <button
                type="button"
                class="{{styles.swatch}}
                  {{if (and anchor (not anchor.seeded)) styles.swatchAnchored}}
                  {{if (eq this.openTone tone) styles.swatchActive}}"
                style={{this.swatchStyle tone}}
                title="Tone {{tone}}{{if anchor (if anchor.seeded ' (seeded)' ' (anchored)')}}"
                {{on "click" (fn this.onSwatchClick tone)}}
              ></button>
              <span
                class="{{styles.toneLabel}} {{if anchor styles.toneLabelVisible}}"
              >{{tone}}</span>
            </div>
          {{/let}}
        {{/each}}
      </div>

      {{#if this.openTone}}
        <DraggableModal
          @title="Tone {{this.openTone}}"
          @position={{this.modalPosition}}
          @onClose={{this.onModalClose}}
        >
          <TonePicker
            @tone={{this.openTone}}
            @anchor={{(this.anchorAt this.openTone)}}
            @token={{(this.tokenAt this.openTone)}}
            @isEndpoint={{or (eq this.openTone 50) (eq this.openTone 500) (eq this.openTone 950)}}
            @onChange={{(fn this.onPickerChange this.openTone)}}
            @onRemove={{(fn this.onRemoveAnchor this.openTone)}}
            @onClose={{this.onModalClose}}
          />
        </DraggableModal>
      {{/if}}
    </div>
  </template>
}
