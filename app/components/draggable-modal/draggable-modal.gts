import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { on } from "@ember/modifier";
import { modifier } from "ember-modifier";
import onClickOutside from "ember-click-outside/modifiers/on-click-outside";
import { htmlSafe } from "@ember/template";
import type { SafeString } from "@ember/template";
import styles from "./draggable-modal.module.css";
import { swatch } from "../ramp-editor/ramp-editor.module.css";
import { concat } from "@ember/helper";
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

  setupModal = modifier(() => {
    // Sync position from args when it changes (new swatch clicked)
    this.x = this.args.position.x;
    this.y = this.args.position.y;

    // Close on Escape
    const onKeyDown = (e: KeyboardEvent) => {
      if (e.key === "Escape") this.args.onClose();
    };

    document.addEventListener("keydown", onKeyDown);

    return () => {
      document.removeEventListener("keydown", onKeyDown);
    };
  });

  onHeaderPointerDown = (e: PointerEvent): void => {
    // Don't initiate drag when clicking buttons inside the header (e.g. close)
    if ((e.target as HTMLElement).closest("button")) return;
    e.preventDefault();
    this.isDragging = true;
    this.dragOffsetX = e.clientX - this.x;
    this.dragOffsetY = e.clientY - this.y;
    (e.currentTarget as Element).setPointerCapture(e.pointerId);
  };

  onHeaderPointerMove = (e: PointerEvent): void => {
    if (!this.isDragging) return;
    const newX = e.clientX - this.dragOffsetX;
    const newY = e.clientY - this.dragOffsetY;
    const maxX = window.innerWidth - 320;
    const maxY = window.innerHeight - 60;
    this.x = Math.min(maxX, Math.max(0, newX));
    this.y = Math.min(maxY, Math.max(0, newY));
  };

  onHeaderPointerUp = (): void => {
    this.isDragging = false;
  };

  <template>
    <div
      class={{styles.modal}}
      style={{this.positionStyle}}
      {{this.setupModal}}
      {{onClickOutside @onClose exceptSelector=(concat "." swatch)}}
    >
      {{log swatch}}
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
