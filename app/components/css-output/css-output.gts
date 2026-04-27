import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { on } from "@ember/modifier";
import { modifier } from "ember-modifier";
import { createHighlighter } from "shiki";
import { generateCss, CSS_OUTPUT_MODES } from "#utils/css-output";
import type { CssOutputMode } from "#utils/css-output";
import type { ColourToken } from "#utils/token-generator";
import PillTabs from "#components/pill-tabs/pill-tabs";
import styles from "./css-output.module.css";

// Lazily initialise a single shared highlighter instance
let highlighterPromise: ReturnType<typeof createHighlighter> | null = null;

function getHighlighter() {
  if (!highlighterPromise) {
    highlighterPromise = createHighlighter({
      themes: ["vitesse-dark"],
      langs: ["css"],
    });
  }
  return highlighterPromise;
}

interface Signature {
  Args: {
    tokens: ColourToken[];
  };
}

export default class CssOutput extends Component<Signature> {
  @tracked highlightedHtml = "";
  @tracked copyLabel = "Copy";
  @tracked isOpen = true;
  @tracked outputMode: CssOutputMode = "oklch";

  get css(): string {
    return generateCss(this.args.tokens, this.outputMode);
  }

  highlightModifier = modifier((el: Element, [css]: [string]) => {
    void getHighlighter().then((hl) => {
      el.innerHTML = hl.codeToHtml(css, {
        lang: "css",
        theme: "vitesse-dark",
      });
    });
  });

  toggleOpen = (): void => {
    this.isOpen = !this.isOpen;
  };

  setOutputMode = (mode: CssOutputMode): void => {
    this.outputMode = mode;
  };

  handleCopy = async (): Promise<void> => {
    await navigator.clipboard.writeText(this.css);
    this.copyLabel = "Copied!";
    setTimeout(() => {
      this.copyLabel = "Copy";
    }, 1500);
  };

  <template>
    <div class={{styles.bar}}>
      <div class={{styles.barHeader}}>
        <button
          type="button"
          class={{styles.toggle}}
          aria-expanded={{this.isOpen}}
          {{on "click" this.toggleOpen}}
        >
          <span class={{styles.toggleIcon}}>{{if this.isOpen "▾" "▸"}}</span>
          <span class={{styles.toggleLabel}}>CSS output</span>
        </button>

        <div class={{styles.barHeaderRight}}>
          <PillTabs
            @options={{CSS_OUTPUT_MODES}}
            @selected={{this.outputMode}}
            @onChange={{this.setOutputMode}}
            @label="CSS output format"
          />

          <button type="button" class={{styles.copyButton}} {{on "click" this.handleCopy}}>
            {{this.copyLabel}}
          </button>
        </div>
      </div>

      {{#if this.isOpen}}
        <div class={{styles.codeBlock}} {{this.highlightModifier this.css}}>
          {{! Shiki returns sanitised HTML }}
          {{! template-lint-disable no-triple-curlies }}
          <pre>{{this.css}}</pre>
        </div>
      {{/if}}
    </div>
  </template>
}
