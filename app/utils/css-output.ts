import type { ColourToken } from "#utils/token-generator";

/**
 * Convert a flat list of colour tokens into a CSS string of custom properties
 * grouped by colour name, wrapped in :root.
 */
export function generateCss(tokens: ColourToken[]): string {
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
      lines.push(`  ${token.variable}: oklch(${token.value});`);
    }
  }

  lines.push("}");
  return lines.join("\n") + "\n";
}
