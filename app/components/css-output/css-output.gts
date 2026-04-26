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
      themes: ["github-light"],
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

  // Re-highlight whenever @css changes
  highlightModifier = modifier((_el: Element, [css]: [string]) => {
    void getHighlighter().then((hl) => {
      this.highlightedHtml = hl.codeToHtml(css, {
        lang: "css",
        theme: "github-light",
      });
    });
  });

  @action async handleCopy(): Promise<void> {
    await navigator.clipboard.writeText(this.args.css);
    this.copyLabel = "Copied!";
    setTimeout(() => {
      this.copyLabel = "Copy";
    }, 1500);
  }

  <template>
    <div class={{styles.wrapper}}>
      <div class={{styles.header}}>
        <span class={{styles.title}}>Generated CSS</span>
        <button type="button" class={{styles.copyButton}} {{on "click" this.handleCopy}}>
          {{this.copyLabel}}
        </button>
      </div>
      {{! Apply modifier to trigger re-highlighting when @css changes }}
      <div class={{styles.codeBlock}} {{this.highlightModifier @css}}>
        {{! Shiki returns sanitised HTML }}
        {{! template-lint-disable no-triple-curlies }}
        {{{this.highlightedHtml}}}
      </div>
    </div>
  </template>
}
