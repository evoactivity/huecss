import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { on } from "@ember/modifier";
import { modifier } from "ember-modifier";
import { htmlSafe } from "@ember/template";
import type { SafeString } from "@ember/template";
import styles from "./draggable-modal.module.css";

export interface ModalPosition {
  x: number;
  y: number;
}

interface Signature {
  Args: {
    title: string;
    position: ModalPosition;
    onClose: () => void;
  };
  Blocks: {
    default: [];
  };
}

export default class DraggableModal extends Component<Signature> {
  @tracked x = 0;
  @tracked y = 0;

  private dragOffsetX = 0;
  private dragOffsetY = 0;
  private isDragging = false;

  get positionStyle(): SafeString {
    return htmlSafe(`left: ${this.x}px; top: ${this.y}px`);
  }

  setupModal = modifier((el: HTMLElement) => {
    // Sync position from args when it changes (new swatch clicked)
    this.x = this.args.position.x;
    this.y = this.args.position.y;

    // Close on Escape
    const onKeyDown = (e: KeyboardEvent) => {
      if (e.key === "Escape") this.args.onClose();
    };

    // Outside-click: only close if the press *started* outside the modal.
    // We use pointerdown (not click) so pointer-captured drags on the hue
    // wheel / sliders don't trigger a false close when the pointer is
    // released outside the modal bounds.
    const onPointerDown = (e: PointerEvent) => {
      if (!el.contains(e.target as Node)) {
        this.args.onClose();
      }
    };

    document.addEventListener("keydown", onKeyDown);
    // Deferred so the pointerdown that opened the modal doesn't immediately
    // fire the handler.
    const timerId = setTimeout(() => {
      document.addEventListener("pointerdown", onPointerDown);
    }, 0);

    return () => {
      clearTimeout(timerId);
      document.removeEventListener("keydown", onKeyDown);
      document.removeEventListener("pointerdown", onPointerDown);
    };
  });

  @action onHeaderPointerDown(e: PointerEvent): void {
    // Don't initiate drag when clicking buttons inside the header (e.g. close)
    if ((e.target as HTMLElement).closest("button")) return;
    e.preventDefault();
    this.isDragging = true;
    this.dragOffsetX = e.clientX - this.x;
    this.dragOffsetY = e.clientY - this.y;
    (e.currentTarget as Element).setPointerCapture(e.pointerId);
  }

  @action onHeaderPointerMove(e: PointerEvent): void {
    if (!this.isDragging) return;
    const newX = e.clientX - this.dragOffsetX;
    const newY = e.clientY - this.dragOffsetY;
    // Clamp to viewport
    const maxX = window.innerWidth - 320;
    const maxY = window.innerHeight - 60; // at least header visible
    this.x = Math.min(maxX, Math.max(0, newX));
    this.y = Math.min(maxY, Math.max(0, newY));
  }

  @action onHeaderPointerUp(): void {
    this.isDragging = false;
  }

  <template>
    <div class={{styles.modal}} style={{this.positionStyle}} {{this.setupModal}}>
      <div
        class={{styles.header}}
        {{on "pointerdown" this.onHeaderPointerDown}}
        {{on "pointermove" this.onHeaderPointerMove}}
        {{on "pointerup" this.onHeaderPointerUp}}
      >
        <span class={{styles.title}}>{{@title}}</span>
        <button
          type="button"
          class={{styles.close}}
          aria-label="Close"
          {{on "click" @onClose}}
        >×</button>
      </div>
      <div class={{styles.body}}>
        {{yield}}
      </div>
    </div>
  </template>
}
