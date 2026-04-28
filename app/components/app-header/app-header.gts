import type { TemplateOnlyComponent } from "@ember/component/template-only";
import GithubMark from "#app/icons/github.svg";
import styles from "./app-header.module.css";

const AppHeader: TemplateOnlyComponent = <template>
  <header class={{styles.header}}>
    <span class={{styles.wordmark}}>hue<span>css</span></span>

    <a
      class={{styles.repoLink}}
      href="https://github.com/evoactivity/huecss"
      target="_blank"
      rel="noopener noreferrer"
      title="View source on GitHub"
      aria-label="View source on GitHub"
    >
      <GithubMark class={{styles.repoIcon}} aria-hidden="true" />
    </a>
  </header>
</template>;

export default AppHeader;
