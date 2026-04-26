import Component from "@glimmer/component";
import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { htmlSafe } from "@ember/template";
import type { SafeString } from "@ember/template";
import type { ColourDefinition } from "#utils/colours";
import type { ActiveColour } from "#utils/token-generator";
import styles from "./colour-picker.module.css";

interface Signature {
  Args: {
    colours: ColourDefinition[];
    activeColours: ActiveColour[];
    onToggle: (colour: ColourDefinition) => void;
  };
}

export default class ColourPicker extends Component<Signature> {
  isActive = (name: string): boolean => {
    return this.args.activeColours.some((a) => a.definition.name === name);
  };

  swatchStyle = (colour: ColourDefinition): SafeString => {
    return htmlSafe(`background: oklch(${colour.lightness} ${colour.chroma} ${colour.hue})`);
  };

  <template>
    <div class={{styles.grid}}>
      {{#each @colours as |colour|}}
        <button
          type="button"
          class="{{styles.swatch}} {{if (this.isActive colour.name) styles.active}}"
          title={{colour.name}}
          aria-pressed={{this.isActive colour.name}}
          {{on "click" (fn @onToggle colour)}}
        >
          <span class={{styles.dot}} style={{this.swatchStyle colour}}></span>
          <span class={{styles.label}}>{{colour.name}}</span>
        </button>
      {{/each}}
    </div>
  </template>
}
