import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { on } from "@ember/modifier";
import type { ColourDefinition } from "#utils/colours";
import { not } from "#utils/helpers";
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

  get previewStyle(): string {
    return `background: oklch(0.577 0.15 ${this.hue})`;
  }

  get nameError(): string | null {
    const trimmed = this.name.trim();
    if (!trimmed) return null;
    if (!/^[a-z][a-z0-9-]*$/.test(trimmed)) {
      return "Only lowercase letters, numbers, and hyphens. Must start with a letter.";
    }
    if (this.args.existingNames.includes(trimmed)) {
      return "A colour with this name already exists.";
    }
    return null;
  }

  get canSubmit(): boolean {
    return this.name.trim().length > 0 && this.nameError === null;
  }

  @action handleNameInput(event: Event): void {
    this.name = (event.target as HTMLInputElement).value;
  }

  @action handleHueInput(event: Event): void {
    const raw = parseFloat((event.target as HTMLInputElement).value);
    this.hue = isNaN(raw) ? 0 : Math.min(360, Math.max(0, raw));
  }

  @action handleSubmit(event: Event): void {
    event.preventDefault();
    if (!this.canSubmit) return;

    this.args.onAdd({
      name: this.name.trim(),
      hue: this.hue,
      lightness: 0.55,
      chroma: 0.15,
    });

    this.name = "";
    this.hue = 0;
  }

  <template>
    <form class={{styles.form}} {{on "submit" this.handleSubmit}}>
      <div class={{styles.field}}>
        <label class={{styles.label}} for="custom-colour-name">Name</label>
        <input
          id="custom-colour-name"
          class={{styles.input}}
          type="text"
          placeholder="e.g. brand"
          value={{this.name}}
          {{on "input" this.handleNameInput}}
        />
        {{#if this.nameError}}
          <span class={{styles.error}}>{{this.nameError}}</span>
        {{/if}}
      </div>

      <div class={{styles.field}}>
        <label class={{styles.label}} for="custom-colour-hue">Hue (0-360)</label>
        <input
          id="custom-colour-hue"
          class="{{styles.input}} {{styles.hueInput}}"
          type="number"
          min="0"
          max="360"
          step="1"
          value={{this.hue}}
          {{on "input" this.handleHueInput}}
        />
      </div>

      <div class={{styles.preview}} style={{this.previewStyle}}></div>

      <button type="submit" class={{styles.addButton}} disabled={{not this.canSubmit}}>
        Add colour
      </button>
    </form>
  </template>
}
