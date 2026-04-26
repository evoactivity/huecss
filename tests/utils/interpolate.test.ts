import { describe, test, expect } from "vitest";
import { seedAnchors, interpolateRamp, revertAnchor } from "#utils/interpolate";
import { DEFAULT_LIGHTNESS_CURVE, DEFAULT_CHROMA_CURVE } from "#utils/spline";
import { TONES } from "#utils/colours";
import type { ColourDefinition } from "#utils/colours";

const blue: ColourDefinition = {
  name: "blue",
  lightness: 0.623,
  chroma: 0.214,
  hue: 259.815,
  lightnessCurve: DEFAULT_LIGHTNESS_CURVE,
  chromaCurve: DEFAULT_CHROMA_CURVE,
};

describe("seedAnchors", () => {
  test("produces exactly 3 anchors at tones 50, 500, 950", () => {
    const anchors = seedAnchors(blue, DEFAULT_LIGHTNESS_CURVE, DEFAULT_CHROMA_CURVE);
    expect(anchors).toHaveLength(3);
    expect(anchors.map((a) => a.tone)).toEqual([50, 500, 950]);
  });

  test("all seeded anchors are marked seeded", () => {
    const anchors = seedAnchors(blue, DEFAULT_LIGHTNESS_CURVE, DEFAULT_CHROMA_CURVE);
    expect(anchors.every((a) => a.seeded)).toBe(true);
  });

  test("tone 500 anchor matches the definition exactly", () => {
    const anchors = seedAnchors(blue, DEFAULT_LIGHTNESS_CURVE, DEFAULT_CHROMA_CURVE);
    const a500 = anchors.find((a) => a.tone === 500)!;
    expect(a500.l).toBeCloseTo(blue.lightness, 3);
    expect(a500.c).toBeCloseTo(blue.chroma, 3);
    expect(a500.h).toBe(blue.hue);
  });

  test("tone 50 is lighter than tone 500", () => {
    const anchors = seedAnchors(blue, DEFAULT_LIGHTNESS_CURVE, DEFAULT_CHROMA_CURVE);
    const a50 = anchors.find((a) => a.tone === 50)!;
    const a500 = anchors.find((a) => a.tone === 500)!;
    expect(a50.l).toBeGreaterThan(a500.l);
  });

  test("tone 950 is darker than tone 500", () => {
    const anchors = seedAnchors(blue, DEFAULT_LIGHTNESS_CURVE, DEFAULT_CHROMA_CURVE);
    const a950 = anchors.find((a) => a.tone === 950)!;
    const a500 = anchors.find((a) => a.tone === 500)!;
    expect(a950.l).toBeLessThan(a500.l);
  });
});

describe("interpolateRamp", () => {
  test("returns a token for every tone", () => {
    const anchors = seedAnchors(blue, DEFAULT_LIGHTNESS_CURVE, DEFAULT_CHROMA_CURVE);
    const tokens = interpolateRamp(anchors, blue, "oklch");
    expect(tokens).toHaveLength(TONES.length);
    expect(tokens.map((t) => t.tone)).toEqual([...TONES]);
  });

  test("all token variable names follow --color-{name}-{tone}", () => {
    const anchors = seedAnchors(blue, DEFAULT_LIGHTNESS_CURVE, DEFAULT_CHROMA_CURVE);
    const tokens = interpolateRamp(anchors, blue, "oklch");
    for (const token of tokens) {
      expect(token.variable).toBe(`--color-blue-${token.tone}`);
    }
  });

  test("tone 50 token is lighter than tone 950 token", () => {
    const anchors = seedAnchors(blue, DEFAULT_LIGHTNESS_CURVE, DEFAULT_CHROMA_CURVE);
    const tokens = interpolateRamp(anchors, blue, "oklch");
    const t50 = tokens.find((t) => t.tone === 50)!;
    const t950 = tokens.find((t) => t.tone === 950)!;
    expect(t50.l).toBeGreaterThan(t950.l);
  });

  test("user anchor is honoured -- pinned tone matches anchor colour", () => {
    const anchors = seedAnchors(blue, DEFAULT_LIGHTNESS_CURVE, DEFAULT_CHROMA_CURVE);
    // Add a user anchor at tone 200 with specific values
    const userAnchor = { tone: 200 as const, l: 0.9, c: 0.05, h: 100, seeded: false };
    const withUser = [...anchors, userAnchor].sort((a, b) => a.tone - b.tone);
    const tokens = interpolateRamp(withUser, blue, "oklch");
    const t200 = tokens.find((t) => t.tone === 200)!;
    // chroma.js interpolates exactly at anchor points
    expect(t200.l).toBeCloseTo(0.9, 2);
    expect(t200.h).toBeCloseTo(100, 0);
  });

  test("works with all interpolation modes", () => {
    const anchors = seedAnchors(blue, DEFAULT_LIGHTNESS_CURVE, DEFAULT_CHROMA_CURVE);
    for (const mode of ["oklch", "oklab", "lch", "lab"] as const) {
      const tokens = interpolateRamp(anchors, blue, mode);
      expect(tokens).toHaveLength(TONES.length);
      expect(tokens.every((t) => isFinite(t.l) && isFinite(t.c))).toBe(true);
    }
  });
});

describe("revertAnchor", () => {
  test("reverting tone 500 returns definition values", () => {
    const reverted = revertAnchor(500, blue, DEFAULT_LIGHTNESS_CURVE, DEFAULT_CHROMA_CURVE);
    expect(reverted.tone).toBe(500);
    expect(reverted.l).toBeCloseTo(blue.lightness, 3);
    expect(reverted.seeded).toBe(true);
  });

  test("reverting tone 50 returns a seeded anchor", () => {
    const reverted = revertAnchor(50, blue, DEFAULT_LIGHTNESS_CURVE, DEFAULT_CHROMA_CURVE);
    expect(reverted.tone).toBe(50);
    expect(reverted.seeded).toBe(true);
    expect(reverted.l).toBeGreaterThan(blue.lightness);
  });
});
