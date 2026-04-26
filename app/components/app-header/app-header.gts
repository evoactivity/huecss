import Component from "@glimmer/component";
import { action } from "@ember/object";
import { on } from "@ember/modifier";
import { fn } from "@ember/helper";
import type { InterpolationMode } from "#utils/interpolate";
import { INTERPOLATION_MODES } from "#utils/interpolate";
import { eq } from "#utils/helpers";

interface Signature {
  Args: {
    interpolationMode: InterpolationMode;
    onModeChange: (mode: InterpolationMode) => void;
  };
}

export default class AppHeader extends Component<Signature> {
  @action onTabClick(mode: InterpolationMode): void {
    this.args.onModeChange(mode);
  }

  <template>
    <header class="app-header">
      <span class="app-header__wordmark">hue<span>css</span></span>

      <div class="app-header__tabs" role="tablist" aria-label="Interpolation mode">
        {{#each INTERPOLATION_MODES as |mode|}}
          <button
            type="button"
            role="tab"
            aria-selected={{eq mode @interpolationMode}}
            class="app-header__tab {{if (eq mode @interpolationMode) 'app-header__tab--active'}}"
            {{on "click" (fn this.onTabClick mode)}}
          >
            {{mode}}
          </button>
        {{/each}}
      </div>
    </header>
  </template>
}
