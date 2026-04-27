import { describe, test, expect } from "vitest";
import { interpolateRamp, colourFromCurve } from "#utils/interpolate";
import { DEFAULT_LIGHTNESS_CURVE, DEFAULT_CHROMA_CURVE } from "#utils/spline";
import { TONES } from "#utils/colours";
import type { ColourDefinition } from "#utils/colours";
import type { ToneAnchor } from "#utils/interpolate";

const blue: ColourDefinition = {
  name: "blue",
  lightness: 0.623,
  chroma: 0.214,
  hue: 259.815,
  lightnessCurve: DEFAULT_LIGHTNESS_CURVE,
  chromaCurve: DEFAULT_CHROMA_CURVE,
};

describe("colourFromCurve", () => {
  test("tone 500 matches the definition lightness and chroma", () => {
    const result = colourFromCurve(500, blue, DEFAULT_LIGHTNESS_CURVE, DEFAULT_CHROMA_CURVE);
    expect(result.l).toBeCloseTo(blue.lightness, 3);
    expect(result.c).toBeCloseTo(blue.chroma, 3);
    expect(result.h).toBe(blue.hue);
  });

  test("tone 50 is lighter than tone 500", () => {
    const t50 = colourFromCurve(50, blue, DEFAULT_LIGHTNESS_CURVE, DEFAULT_CHROMA_CURVE);
    const t500 = colourFromCurve(500, blue, DEFAULT_LIGHTNESS_CURVE, DEFAULT_CHROMA_CURVE);
    expect(t50.l).toBeGreaterThan(t500.l);
  });

  test("tone 950 is darker than tone 500", () => {
    const t950 = colourFromCurve(950, blue, DEFAULT_LIGHTNESS_CURVE, DEFAULT_CHROMA_CURVE);
    const t500 = colourFromCurve(500, blue, DEFAULT_LIGHTNESS_CURVE, DEFAULT_CHROMA_CURVE);
    expect(t950.l).toBeLessThan(t500.l);
  });
});

describe("interpolateRamp", () => {
  test("returns a token for every tone with no user anchors", () => {
    const tokens = interpolateRamp(
      [],
      blue,
      "oklch",
      DEFAULT_LIGHTNESS_CURVE,
      DEFAULT_CHROMA_CURVE,
    );
    expect(tokens).toHaveLength(TONES.length);
    expect(tokens.map((t) => t.tone)).toEqual([...TONES]);
  });

  test("all token variable names follow --color-{name}-{tone}", () => {
    const tokens = interpolateRamp(
      [],
      blue,
      "oklch",
      DEFAULT_LIGHTNESS_CURVE,
      DEFAULT_CHROMA_CURVE,
    );
    for (const token of tokens) {
      expect(token.variable).toBe(`--color-blue-${token.tone}`);
    }
  });

  test("tone 50 token is lighter than tone 950 token", () => {
    const tokens = interpolateRamp(
      [],
      blue,
      "oklch",
      DEFAULT_LIGHTNESS_CURVE,
      DEFAULT_CHROMA_CURVE,
    );
    const t50 = tokens.find((t) => t.tone === 50)!;
    const t950 = tokens.find((t) => t.tone === 950)!;
    expect(t50.l).toBeGreaterThan(t950.l);
  });

  test("user anchor is honoured -- pinned tone matches anchor colour", () => {
    const userAnchor: ToneAnchor = { tone: 200 as const, l: 0.9, c: 0.05, h: 100 };
    const tokens = interpolateRamp(
      [userAnchor],
      blue,
      "oklch",
      DEFAULT_LIGHTNESS_CURVE,
      DEFAULT_CHROMA_CURVE,
    );
    const t200 = tokens.find((t) => t.tone === 200)!;
    expect(t200.l).toBeCloseTo(0.9, 2);
    expect(t200.h).toBeCloseTo(100, 0);
  });

  test("user anchor at tone 50 overrides the bezier endpoint", () => {
    const userAnchor: ToneAnchor = { tone: 50 as const, l: 0.99, c: 0.01, h: 260 };
    const tokens = interpolateRamp(
      [userAnchor],
      blue,
      "oklch",
      DEFAULT_LIGHTNESS_CURVE,
      DEFAULT_CHROMA_CURVE,
    );
    const t50 = tokens.find((t) => t.tone === 50)!;
    expect(t50.l).toBeCloseTo(0.99, 2);
  });

  test("works with all interpolation modes", () => {
    for (const mode of ["oklch", "oklab", "lch", "lab"] as const) {
      const tokens = interpolateRamp([], blue, mode, DEFAULT_LIGHTNESS_CURVE, DEFAULT_CHROMA_CURVE);
      expect(tokens).toHaveLength(TONES.length);
      expect(tokens.every((t) => isFinite(t.l) && isFinite(t.c))).toBe(true);
    }
  });
});
