import Component from "@glimmer/component";
import { service } from "@ember/service";
import { INTERPOLATION_MODES } from "#utils/interpolate";
import type ColourStudio from "#services/colour-studio";
import PillTabs from "#components/pill-tabs/pill-tabs";
import styles from "./app-header.module.css";

export default class AppHeader extends Component {
  @service("colour-studio") declare studio: ColourStudio;

  <template>
    <header class={{styles.header}}>
      <span class={{styles.wordmark}}>hue<span>css</span></span>

      <PillTabs
        @options={{INTERPOLATION_MODES}}
        @selected={{this.studio.interpolationMode}}
        @onChange={{this.studio.setInterpolationMode}}
        @label="Interpolation mode"
      />
    </header>
  </template>
}
