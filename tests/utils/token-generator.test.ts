import { describe, test, expect } from "vitest";
import { generateTokens, activateColour } from "#utils/token-generator";
import { TONES } from "#utils/colours";
import type { ActiveColour, ColourToken } from "#utils/token-generator";
import { makeAnchor } from "#utils/interpolate";

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

  test("starts with anchors at tones 50, 500, and 950", () => {
    const active = activateColour(blueDef);
    expect(active.anchors).toHaveLength(3);
    expect(active.anchors.map((a) => a.tone)).toEqual([50, 500, 950]);
  });

  test("tone 500 anchor matches the definition colour", () => {
    const active = activateColour(blueDef);
    const a500 = active.anchors.find((a) => a.tone === 500)!;
    expect(a500.l).toBeCloseTo(blueDef.lightness, 3);
    expect(a500.c).toBeCloseTo(blueDef.chroma, 3);
    expect(a500.h).toBeCloseTo(blueDef.hue, 1);
  });

  test("adding a user anchor at a tone pins that colour", () => {
    const active = activateColour(blueDef);
    active.anchors.push(makeAnchor(200, 0.9, 0.02, 100));
    const tokens = generateTokens([active]);
    const t200 = tokens.find((t) => t.tone === 200)!;
    expect(t200.l).toBeCloseTo(0.9, 1);
  });
});
