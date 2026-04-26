import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { on } from "@ember/modifier";
import { modifier } from "ember-modifier";
import { createHighlighter } from "shiki";
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
    css: string;
  };
}

export default class CssOutput extends Component<Signature> {
  @tracked highlightedHtml = "";
  @tracked copyLabel = "Copy";
  @tracked isOpen = true;

  highlightModifier = modifier((el: Element, [css]: [string]) => {
    void getHighlighter().then((hl) => {
      el.innerHTML = hl.codeToHtml(css, {
        lang: "css",
        theme: "vitesse-dark",
      });
    });
  });

  @action toggleOpen(): void {
    this.isOpen = !this.isOpen;
  }

  @action async handleCopy(): Promise<void> {
    await navigator.clipboard.writeText(this.args.css);
    this.copyLabel = "Copied!";
    setTimeout(() => {
      this.copyLabel = "Copy";
    }, 1500);
  }

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

        <button type="button" class={{styles.copyButton}} {{on "click" this.handleCopy}}>
          {{this.copyLabel}}
        </button>
      </div>

      {{#if this.isOpen}}
        <div class={{styles.codeBlock}} {{this.highlightModifier @css}}>
          {{! Shiki returns sanitised HTML }}
          {{! template-lint-disable no-triple-curlies }}
          <pre>{{@css}}</pre>
        </div>
      {{/if}}
    </div>
  </template>
}
