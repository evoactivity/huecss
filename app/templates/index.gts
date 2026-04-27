import Component from "@glimmer/component";
import { service } from "@ember/service";
import type ColourStudio from "#services/colour-studio";
import AppHeader from "#components/app-header/app-header";
import ColourPicker from "#components/colour-picker/colour-picker";
import CustomColourForm from "#components/custom-colour-form/custom-colour-form";
import RampEditor from "#components/ramp-editor/ramp-editor";
import CssOutput from "#components/css-output/css-output";

export default class IndexRoute extends Component {
  @service declare colourStudio: ColourStudio;

  <template>
    <AppHeader />

    <div class="app-body">
      {{! Left panel }}
      <aside class="app-panel">
        <div class="app-panel__section">
          <p class="app-panel__label">Colours</p>
          <ColourPicker
            @colours={{this.colourStudio.allColours}}
            @activeColours={{this.colourStudio.activeColours}}
            @onToggle={{this.colourStudio.toggleColour}}
          />
        </div>

        <div class="app-panel__section">
          <p class="app-panel__label">Custom colour</p>
          <CustomColourForm
            @existingNames={{this.colourStudio.existingNames}}
            @onAdd={{this.colourStudio.addCustomColour}}
          />
        </div>
      </aside>

      {{! Right workspace }}
      <div class="app-workspace">
        <div class="app-workspace__scroll">
          {{#if this.colourStudio.hasActiveColours}}
            {{#each this.colourStudio.activeColours as |active|}}
              <div class="workspace-ramp">
                <p class="workspace-ramp__name">{{active.definition.name}}</p>
                <RampEditor
                  @active={{active}}
                  @tokens={{(this.colourStudio.tokensFor active.definition.name)}}
                />
              </div>
            {{/each}}
          {{else}}
            <div class="app-workspace__empty">
              <span>Select a colour from the panel to get started.</span>
            </div>
          {{/if}}
        </div>

        {{#if this.colourStudio.hasActiveColours}}
          <CssOutput @tokens={{this.colourStudio.tokens}} />
        {{/if}}
      </div>
    </div>
  </template>
}
