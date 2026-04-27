import chroma from "chroma-js";
import type { ColourToken } from "#utils/token-generator";

export type CssOutputMode = "oklch" | "rgb" | "hsl" | "hex";

export const CSS_OUTPUT_MODES: CssOutputMode[] = ["oklch", "rgb", "hsl", "hex"];

/** Format a single token value in the requested output mode. */
function formatValue(token: ColourToken, mode: CssOutputMode): string {
  if (mode === "oklch") {
    return `oklch(${token.value})`;
  }

  const colour = chroma.oklch(token.l, token.c, token.h);

  if (mode === "hex") {
    return colour.hex();
  }

  if (mode === "rgb") {
    const [r, g, b] = colour.rgb();
    return `rgb(${Math.round(r)} ${Math.round(g)} ${Math.round(b)})`;
  }

  // hsl
  const [h, s, l] = colour.hsl();
  const hRound = Math.round(h ?? 0);
  const sRound = Math.round((s ?? 0) * 100);
  const lRound = Math.round((l ?? 0) * 100);
  return `hsl(${hRound} ${sRound}% ${lRound}%)`;
}

/**
 * Convert a flat list of colour tokens into a CSS string of custom properties
 * grouped by colour name, wrapped in :root.
 */
export function generateCss(tokens: ColourToken[], mode: CssOutputMode = "oklch"): string {
  if (tokens.length === 0) return ":root {\n}\n";

  // Group tokens by colour name, preserving insertion order
  const groups = new Map<string, ColourToken[]>();
  for (const token of tokens) {
    let group = groups.get(token.name);
    if (!group) {
      group = [];
      groups.set(token.name, group);
    }
    group.push(token);
  }

  const lines: string[] = [":root {"];

  let first = true;
  for (const [name, colourTokens] of groups) {
    if (!first) lines.push("");
    first = false;

    lines.push(`  /* ${name} */`);
    for (const token of colourTokens) {
      lines.push(`  ${token.variable}: ${formatValue(token, mode)};`);
    }
  }

  lines.push("}");
  return lines.join("\n") + "\n";
}
