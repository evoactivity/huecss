import Component from "@glimmer/component";
import { service } from "@ember/service";
import { on } from "@ember/modifier";
import { fn } from "@ember/helper";
import { INTERPOLATION_MODES } from "#utils/interpolate";
import { eq } from "#utils/helpers";
import type ColourStudio from "#services/colour-studio";

export default class AppHeader extends Component {
  @service("colour-studio") declare studio: ColourStudio;

  <template>
    <header class="app-header">
      <span class="app-header__wordmark">hue<span>css</span></span>

      <div class="app-header__tabs" role="tablist" aria-label="Interpolation mode">
        {{#each INTERPOLATION_MODES as |mode|}}
          <button
            type="button"
            role="tab"
            aria-selected={{eq mode this.studio.interpolationMode}}
            class="app-header__tab
              {{if (eq mode this.studio.interpolationMode) 'app-header__tab--active'}}"
            {{on "click" (fn this.studio.setInterpolationMode mode)}}
          >
            {{mode}}
          </button>
        {{/each}}
      </div>
    </header>
  </template>
}
