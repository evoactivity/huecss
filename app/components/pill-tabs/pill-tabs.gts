import Component from "@glimmer/component";
import { on } from "@ember/modifier";
import { fn, concat } from "@ember/helper";
import { eq } from "#utils/helpers";
import styles from "./pill-tabs.module.css";

interface Signature<T extends string> {
  Args: {
    options: readonly T[];
    selected: T;
    onChange: (value: T) => void;
    label?: string;
  };
}

export default class PillTabs<T extends string> extends Component<Signature<T>> {
  <template>
    <div class={{styles.tabs}} role="tablist" aria-label={{@label}}>
      {{#each @options as |option|}}
        <button
          type="button"
          role="tab"
          aria-selected={{eq option @selected}}
          class={{if (eq option @selected) (concat styles.tab " " styles.tabActive) styles.tab}}
          {{on "click" (fn @onChange option)}}
        >
          {{option}}
        </button>
      {{/each}}
    </div>
  </template>
}
