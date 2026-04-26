import { describe, test, expect } from "vitest";
import { generateTokens } from "#utils/token-generator";
import { TONES } from "#utils/colours";
import type { ActiveColour, ColourToken } from "#utils/token-generator";
import type { BezierCurve } from "#utils/spline";

const blue: ActiveColour = {
  definition: { name: "blue", lightness: 0.546, hue: 264.052, chroma: 0.232 },
};

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

  test("hue is constant across all tones for a given colour", () => {
    const tokens = generateTokens([blue]);
    for (const token of tokens) {
      expect(token.h).toBe(264.052);
    }
  });

  test("tone 500 always equals the definition lightness and chroma exactly", () => {
    const tokens = generateTokens([blue]);
    const t500 = tokens.find((t) => t.tone === 500)!;
    expect(t500.l).toBeCloseTo(blue.definition.lightness, 3);
    expect(t500.c).toBeCloseTo(blue.definition.chroma, 3);
  });

  test("tone 500 is unchanged when a curve override is applied", () => {
    const shiftedCurve: BezierCurve = {
      p0y: 0.9,
      cp0x: 0.1,
      cp0y: 0.85,
      cpa0x: 0.4,
      cpa0y: 0.6,
      cpa1x: 0.6,
      cpa1y: 0.4,
      cp1x: 0.9,
      cp1y: 0.1,
      p1y: 0.05,
    };
    const withOverride: ActiveColour = {
      ...blue,
      curveOverride: { lightness: shiftedCurve },
    };
    const tokens = generateTokens([withOverride]);
    const t500 = tokens.find((t) => t.tone === 500)!;
    expect(t500.l).toBeCloseTo(blue.definition.lightness, 3);
  });

  test("lightness decreases from tone 50 to tone 950", () => {
    const tokens = generateTokens([blue]);
    const ls = tokens.map((t: ColourToken) => t.l);
    for (let i = 1; i < ls.length; i++) {
      expect(ls[i]).toBeLessThan(ls[i - 1]! + 1e-6);
    }
  });

  test("chroma never exceeds the definition chroma", () => {
    const tokens = generateTokens([blue]);
    for (const token of tokens) {
      expect(token.c).toBeLessThanOrEqual(blue.definition.chroma + 1e-6);
    }
  });

  test("flat lightness curve produces definition lightness at all tones", () => {
    // Flat at ANCHOR_Y (0.5) -- normalises to 1.0 everywhere
    const flatLightness: BezierCurve = {
      p0y: 0.5,
      cp0x: 0.1,
      cp0y: 0.5,
      cpa0x: 0.4,
      cpa0y: 0.5,
      cpa1x: 0.6,
      cpa1y: 0.5,
      cp1x: 0.9,
      cp1y: 0.5,
      p1y: 0.5,
    };
    const withOverride: ActiveColour = {
      ...blue,
      curveOverride: { lightness: flatLightness },
    };
    const tokens = generateTokens([withOverride]);
    // Flat curve normalises to 1.0 everywhere, so all tones get definition.lightness
    for (const token of tokens) {
      expect(token.l).toBeCloseTo(blue.definition.lightness, 3);
    }
  });

  test("generates tokens for multiple colours independently", () => {
    const red: ActiveColour = {
      definition: { name: "red", lightness: 0.577, hue: 27.325, chroma: 0.2 },
    };
    const tokens = generateTokens([blue, red]);
    expect(tokens).toHaveLength(TONES.length * 2);
    const names = [...new Set(tokens.map((t: ColourToken) => t.name))];
    expect(names).toEqual(["blue", "red"]);
  });

  test("returns empty array for no active colours", () => {
    expect(generateTokens([])).toEqual([]);
  });
});
