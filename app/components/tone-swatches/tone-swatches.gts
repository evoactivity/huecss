import Component from "@glimmer/component";
import type { ColourToken } from "#utils/token-generator";
import styles from "./tone-swatches.module.css";

interface Signature {
  Args: {
    /** All tokens -- component groups them by colour name internally */
    tokens: ColourToken[];
  };
}

export default class ToneSwatches extends Component<Signature> {
  get groupedTokens(): Map<string, ColourToken[]> {
    const groups = new Map<string, ColourToken[]>();
    for (const token of this.args.tokens) {
      let group = groups.get(token.name);
      if (!group) {
        group = [];
        groups.set(token.name, group);
      }
      group.push(token);
    }
    return groups;
  }

  get colourGroups(): Array<{ name: string; tokens: ColourToken[] }> {
    return Array.from(this.groupedTokens.entries()).map(([name, tokens]) => ({ name, tokens }));
  }

  swatchStyle = (token: ColourToken): string => {
    return `background: oklch(${token.l} ${token.c} ${token.h})`;
  };

  <template>
    {{#each this.colourGroups as |group|}}
      <div class={{styles.colour}}>
        <span class={{styles.colourName}}>{{group.name}}</span>
        <div class={{styles.swatches}}>
          {{#each group.tokens as |token|}}
            <div
              class={{styles.swatch}}
              style={{this.swatchStyle token}}
              title="{{token.variable}}: oklch({{token.value}})"
            >
              <span class={{styles.toneLabel}}>{{token.tone}}</span>
            </div>
          {{/each}}
        </div>
      </div>
    {{/each}}
  </template>
}
