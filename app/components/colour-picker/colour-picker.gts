import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { on } from "@ember/modifier";
import { fn } from "@ember/helper";
import type { ColourDefinition } from "#utils/colours";
import type { ActiveColour, ColourToken, CurveOverride } from "#utils/token-generator";
import type { ToneAnchor } from "#utils/interpolate";
import { eq } from "#utils/helpers";
import RampEditor from "#components/ramp-editor/ramp-editor";
import styles from "./colour-picker.module.css";

interface Signature {
  Args: {
    colours: ColourDefinition[];
    activeColours: ActiveColour[];
    tokens: ColourToken[];
    onToggle: (colour: ColourDefinition) => void;
    onSetAnchors: (name: string, anchors: ToneAnchor[]) => void;
    onCurveOverride: (name: string, override: CurveOverride | undefined) => void;
  };
}

export default class ColourPicker extends Component<Signature> {
  @tracked expandedName: string | null = null;

  isActive = (name: string): boolean => {
    return this.args.activeColours.some((a) => a.definition.name === name);
  };

  activeFor = (name: string): ActiveColour | undefined => {
    return this.args.activeColours.find((a) => a.definition.name === name);
  };

  tokensFor = (name: string): ColourToken[] => {
    return this.args.tokens.filter((t) => t.name === name);
  };

  swatchStyle = (colour: ColourDefinition): string => {
    return `background: oklch(${colour.lightness} ${colour.chroma} ${colour.hue})`;
  };

  @action toggleExpand(name: string): void {
    this.expandedName = this.expandedName === name ? null : name;
  }

  @action handleToggle(colour: ColourDefinition): void {
    if (this.isActive(colour.name)) {
      this.expandedName = null;
    }
    this.args.onToggle(colour);
  }

  @action handleSetAnchors(name: string, anchors: ToneAnchor[]): void {
    this.args.onSetAnchors(name, anchors);
  }

  <template>
    <div class={{styles.grid}}>
      {{#each @colours as |colour|}}
        <button
          type="button"
          class="{{styles.swatch}} {{if (this.isActive colour.name) styles.selected}}"
          title={{colour.name}}
          {{on "click" (fn this.handleToggle colour)}}
        >
          <span class={{styles.swatchColour}} style={{this.swatchStyle colour}}></span>
          <span class={{styles.label}}>{{colour.name}}</span>
        </button>

        {{#if (this.isActive colour.name)}}
          {{#if (eq this.expandedName colour.name)}}
            <div class={{styles.expandedColour}}>
              <div class={{styles.expandedHeader}}>
                <strong>{{colour.name}}</strong>
              </div>
              {{#let (this.activeFor colour.name) as |active|}}
                {{#if active}}
                  <RampEditor
                    @active={{active}}
                    @tokens={{(this.tokensFor colour.name)}}
                    @onSetAnchors={{(fn this.handleSetAnchors colour.name)}}
                  />
                {{/if}}
              {{/let}}
            </div>
          {{else}}
            <button
              type="button"
              class={{styles.swatch}}
              {{on "click" (fn this.toggleExpand colour.name)}}
            >
              Edit ramp
            </button>
          {{/if}}
        {{/if}}
      {{/each}}
    </div>
  </template>
}
