import Component from "@glimmer/component";
import { action } from "@ember/object";
import { on } from "@ember/modifier";
import styles from "./gradient-slider.module.css";

interface Signature {
  Args: {
    label: string;
    min: number;
    max: number;
    step: number;
    value: number;
    /** CSS gradient string for the track, e.g. "linear-gradient(to right, oklch(...))" */
    gradient: string;
    /** CSS colour string for the thumb, showing the current value */
    thumbColour: string;
    /** Display value string, e.g. "0.55" or "264°" */
    displayValue: string;
    onChange: (value: number) => void;
  };
}

export default class GradientSlider extends Component<Signature> {
  @action onInput(e: Event): void {
    this.args.onChange(parseFloat((e.target as HTMLInputElement).value));
  }

  get trackStyle(): string {
    return `--gradient: ${this.args.gradient}; --thumb-colour: ${this.args.thumbColour}`;
  }

  <template>
    <div class={{styles.wrapper}}>
      <div class={{styles.label}}>
        <span class={{styles.labelText}}>{{@label}}</span>
        <span class={{styles.labelValue}}>{{@displayValue}}</span>
      </div>
      <div class={{styles.trackWrapper}} style={{this.trackStyle}}>
        <div class={{styles.track}}></div>
        <input
          class={{styles.input}}
          type="range"
          min={{@min}}
          max={{@max}}
          step={{@step}}
          value={{@value}}
          {{on "input" this.onInput}}
        />
      </div>
    </div>
  </template>
}
