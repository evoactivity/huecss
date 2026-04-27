import { describe, test, expect } from "vitest";
import { generateCss } from "#utils/css-output";
import { generateTokens, activateColour } from "#utils/token-generator";

const blue = activateColour({ name: "blue", lightness: 0.546, hue: 264.052, chroma: 0.232 });

describe("generateCss", () => {
  test("returns a :root block for empty tokens", () => {
    expect(generateCss([])).toBe(":root {\n}\n");
  });

  test("wraps all properties in :root", () => {
    const css = generateCss(generateTokens([blue]));
    expect(css).toMatch(/^:root \{/);
    expect(css).toMatch(/\}[\n]?$/);
  });

  test("oklch mode: each token produces an oklch custom property", () => {
    const tokens = generateTokens([blue]);
    const css = generateCss(tokens, "oklch");
    for (const token of tokens) {
      expect(css).toContain(`${token.variable}: oklch(${token.value});`);
    }
  });

  test("rgb mode: each token produces an rgb custom property", () => {
    const tokens = generateTokens([blue]);
    const css = generateCss(tokens, "rgb");
    for (const token of tokens) {
      expect(css).toContain(`${token.variable}: rgb(`);
    }
  });

  test("hsl mode: each token produces an hsl custom property", () => {
    const tokens = generateTokens([blue]);
    const css = generateCss(tokens, "hsl");
    for (const token of tokens) {
      expect(css).toContain(`${token.variable}: hsl(`);
    }
  });

  test("hex mode: each token produces a hex custom property", () => {
    const tokens = generateTokens([blue]);
    const css = generateCss(tokens, "hex");
    for (const token of tokens) {
      expect(css).toContain(`${token.variable}: #`);
    }
  });

  test("defaults to oklch when no mode is given", () => {
    const tokens = generateTokens([blue]);
    const css = generateCss(tokens);
    for (const token of tokens) {
      expect(css).toContain(`${token.variable}: oklch(${token.value});`);
    }
  });

  test("includes a comment for each colour group", () => {
    const css = generateCss(generateTokens([blue]));
    expect(css).toContain("/* blue */");
  });

  test("separates multiple colour groups with a blank line", () => {
    const red = activateColour({ name: "red", lightness: 0.577, hue: 27.325, chroma: 0.2 });
    const css = generateCss(generateTokens([blue, red]));
    expect(css).toContain("/* blue */");
    expect(css).toContain("/* red */");
    expect(css).toMatch(/;\n\n\s+\/\*/);
  });

  test("output ends with a newline", () => {
    const css = generateCss(generateTokens([blue]));
    expect(css.endsWith("\n")).toBe(true);
  });
});
