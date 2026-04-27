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
    const tokens = interpolateRamp([], blue, DEFAULT_LIGHTNESS_CURVE, DEFAULT_CHROMA_CURVE);
    expect(tokens).toHaveLength(TONES.length);
    expect(tokens.map((t) => t.tone)).toEqual([...TONES]);
  });

  test("all token variable names follow --color-{name}-{tone}", () => {
    const tokens = interpolateRamp([], blue, DEFAULT_LIGHTNESS_CURVE, DEFAULT_CHROMA_CURVE);
    for (const token of tokens) {
      expect(token.variable).toBe(`--color-blue-${token.tone}`);
    }
  });

  test("tone 50 token is lighter than tone 950 token", () => {
    const tokens = interpolateRamp([], blue, DEFAULT_LIGHTNESS_CURVE, DEFAULT_CHROMA_CURVE);
    const t50 = tokens.find((t) => t.tone === 50)!;
    const t950 = tokens.find((t) => t.tone === 950)!;
    expect(t50.l).toBeGreaterThan(t950.l);
  });

  test("user anchor is honoured -- pinned tone matches anchor colour", () => {
    const userAnchor: ToneAnchor = { tone: 200 as const, l: 0.9, c: 0.05, h: 100 };
    const tokens = interpolateRamp(
      [userAnchor],
      blue,
      DEFAULT_LIGHTNESS_CURVE,
      DEFAULT_CHROMA_CURVE,
    );
    const t200 = tokens.find((t) => t.tone === 200)!;
    expect(t200.l).toBeCloseTo(0.9, 4);
    expect(t200.c).toBeCloseTo(0.05, 4);
    expect(t200.h).toBeCloseTo(100, 3);
  });

  test("user anchor at tone 50 overrides the bezier endpoint", () => {
    const userAnchor: ToneAnchor = { tone: 50 as const, l: 0.99, c: 0.01, h: 260 };
    const tokens = interpolateRamp(
      [userAnchor],
      blue,
      DEFAULT_LIGHTNESS_CURVE,
      DEFAULT_CHROMA_CURVE,
    );
    const t50 = tokens.find((t) => t.tone === 50)!;
    expect(t50.l).toBeCloseTo(0.99, 4);
    expect(t50.c).toBeCloseTo(0.01, 4);
    expect(t50.h).toBeCloseTo(260, 3);
  });

  test("anchored tones round-trip exactly even for out-of-gamut OKLCH", () => {
    // oklch(63.7% 0.237 221.8) sits outside the sRGB gamut. Previously
    // chroma-js silently gamut-clipped the value into sRGB and the token
    // came out as something like oklch(68.13% 0.1575 240.54). The fix
    // interpolates in OKLCH directly so the anchor passes through verbatim.
    const userAnchor: ToneAnchor = { tone: 500 as const, l: 0.637, c: 0.237, h: 221.8 };
    const tokens = interpolateRamp(
      [userAnchor],
      blue,
      DEFAULT_LIGHTNESS_CURVE,
      DEFAULT_CHROMA_CURVE,
    );
    const t500 = tokens.find((t) => t.tone === 500)!;
    expect(t500.l).toBeCloseTo(0.637, 4);
    expect(t500.c).toBeCloseTo(0.237, 4);
    expect(t500.h).toBeCloseTo(221.8, 3);
  });

  test("hue inherits from the chromatic neighbour when crossing an achromatic anchor", () => {
    // tone 50 is grey (c=0), tone 500 has hue 100, tone 950 is grey (c=0).
    // For tones between the grey endpoints and tone 500 we expect the hue
    // to track 100 rather than drift toward 0.
    const greyTop: ToneAnchor = { tone: 50 as const, l: 0.97, c: 0, h: 0 };
    const chromatic: ToneAnchor = { tone: 500 as const, l: 0.5, c: 0.2, h: 100 };
    const greyBottom: ToneAnchor = { tone: 950 as const, l: 0.15, c: 0, h: 0 };
    const tokens = interpolateRamp(
      [greyTop, chromatic, greyBottom],
      blue,
      DEFAULT_LIGHTNESS_CURVE,
      DEFAULT_CHROMA_CURVE,
    );
    for (const tone of [200, 300, 400, 600, 700, 800]) {
      const token = tokens.find((t) => t.tone === tone)!;
      expect(token.h).toBeCloseTo(100, 3);
    }
  });

  test("hue takes the shorter arc between two chromatic anchors", () => {
    // Anchor 50 at hue 350, anchor 950 at hue 10. Shorter arc is 350 → 0 → 10
    // (a 20 degree sweep), not 350 → 180 → 10.
    const top: ToneAnchor = { tone: 50 as const, l: 0.95, c: 0.05, h: 350 };
    const bottom: ToneAnchor = { tone: 950 as const, l: 0.2, c: 0.05, h: 10 };
    const tokens = interpolateRamp(
      [top, bottom],
      blue,
      DEFAULT_LIGHTNESS_CURVE,
      DEFAULT_CHROMA_CURVE,
    );
    // Tone 500 sits half way (4/9 of the way actually since the anchors
    // are at toneToX(50)=0 and toneToX(950)=1, and tone 500 sits at 0.5).
    // We just check the hue stays close to the short arc, never near 180.
    const t500 = tokens.find((t) => t.tone === 500)!;
    // Short arc midpoint of 350..10 is 0 (or 360).
    const distToZero = Math.min(Math.abs(t500.h - 0), Math.abs(t500.h - 360));
    expect(distToZero).toBeLessThan(10);
  });
});
