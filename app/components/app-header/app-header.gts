import type { TemplateOnlyComponent } from "@ember/component/template-only";
import styles from "./app-header.module.css";

const AppHeader: TemplateOnlyComponent = <template>
  <header class={{styles.header}}>
    <span class={{styles.wordmark}}>hue<span>css</span></span>
  </header>
</template>;

export default AppHeader;
