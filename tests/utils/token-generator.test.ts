import { describe, test, expect } from "vitest";
import { generateTokens, activateColour } from "#utils/token-generator";
import { TONES } from "#utils/colours";
import type { ActiveColour, ColourToken } from "#utils/token-generator";

const blueDef = { name: "blue", lightness: 0.546, hue: 264.052, chroma: 0.232 };
const blue: ActiveColour = activateColour(blueDef);

describe("generateTokens", () => {
  test("returns one token per tone per colour", () => {
    const tokens = generateTokens([blue]);
    expect(tokens).toHaveLength(TONES.length);
  });

  test("token variable names follow --color-{name}-{tone} pattern", () => {
    const tokens = generateTokens([blue]);
    for (const token of tokens) {
      expect(token.variable).toBe(`--color-blue-${token.tone}`);
    }
  });

  test("tone 50 is lighter than tone 950", () => {
    const tokens = generateTokens([blue]);
    const t50 = tokens.find((t) => t.tone === 50)!;
    const t950 = tokens.find((t) => t.tone === 950)!;
    expect(t50.l).toBeGreaterThan(t950.l);
  });

  test("generates tokens for multiple colours independently", () => {
    const red = activateColour({ name: "red", lightness: 0.577, hue: 27.325, chroma: 0.2 });
    const tokens = generateTokens([blue, red]);
    expect(tokens).toHaveLength(TONES.length * 2);
    const names = [...new Set(tokens.map((t: ColourToken) => t.name))];
    expect(names).toEqual(["blue", "red"]);
  });

  test("returns empty array for no active colours", () => {
    expect(generateTokens([])).toEqual([]);
  });

  test("adding a user anchor at a tone pins that colour", () => {
    const withAnchor: ActiveColour = {
      ...blue,
      anchors: [
        ...blue.anchors,
        { tone: 200 as const, l: 0.9, c: 0.02, h: 100, seeded: false },
      ].sort((a, b) => a.tone - b.tone),
    };
    const tokens = generateTokens([withAnchor]);
    const t200 = tokens.find((t) => t.tone === 200)!;
    expect(t200.l).toBeCloseTo(0.9, 1);
  });
});
