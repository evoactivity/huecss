import { describe, test, expect } from "vitest";
import { evaluateBezier, toneToX } from "#utils/spline";
import type { BezierCurve } from "#utils/spline";

// Passes through anchor (0.5, 0.5) with handles placed symmetrically
const SYMMETRIC: BezierCurve = {
  p0y: 0,
  cp0x: 0.1,
  cp0y: 0,
  cpa0x: 0.4,
  cpa0y: 0.5,
  cpa1x: 0.6,
  cpa1y: 0.5,
  cp1x: 0.9,
  cp1y: 1.0,
  p1y: 1.0,
};

// Flat curve where all y values equal ANCHOR_Y (0.5)
const FLAT: BezierCurve = {
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

describe("toneToX", () => {
  test("tone 50 maps to 0", () => {
    expect(toneToX(50)).toBe(0);
  });

  test("tone 950 maps to 1", () => {
    expect(toneToX(950)).toBe(1);
  });

  test("tone 500 maps to 0.5", () => {
    expect(toneToX(500)).toBeCloseTo(0.5);
  });
});

describe("evaluateBezier", () => {
  test("returns p0y at x=0", () => {
    expect(evaluateBezier(SYMMETRIC, 0)).toBe(0);
    expect(evaluateBezier(FLAT, 0)).toBe(0.5);
  });

  test("returns p1y at x=1", () => {
    expect(evaluateBezier(SYMMETRIC, 1)).toBe(1.0);
    expect(evaluateBezier(FLAT, 1)).toBe(0.5);
  });

  test("always returns ANCHOR_Y (0.5) at x=0.5", () => {
    expect(evaluateBezier(SYMMETRIC, 0.5)).toBeCloseTo(0.5, 5);
    expect(evaluateBezier(FLAT, 0.5)).toBeCloseTo(0.5, 5);
  });

  test("clamps below 0", () => {
    expect(evaluateBezier(SYMMETRIC, -1)).toBe(0);
  });

  test("clamps above 1", () => {
    expect(evaluateBezier(SYMMETRIC, 2)).toBe(1.0);
  });

  test("flat curve returns 0.5 at all x positions", () => {
    for (const x of [0, 0.1, 0.25, 0.5, 0.75, 0.9, 1]) {
      expect(evaluateBezier(FLAT, x)).toBeCloseTo(0.5, 3);
    }
  });

  test("default lightness curve always passes through anchor at x=0.5", async () => {
    const { DEFAULT_LIGHTNESS_CURVE } = await import("#utils/spline");
    expect(evaluateBezier(DEFAULT_LIGHTNESS_CURVE, 0.5)).toBeCloseTo(0.5, 5);
  });

  test("default lightness curve is higher before anchor and lower after", async () => {
    const { DEFAULT_LIGHTNESS_CURVE } = await import("#utils/spline");
    expect(evaluateBezier(DEFAULT_LIGHTNESS_CURVE, 0)).toBeGreaterThan(0.5);
    expect(evaluateBezier(DEFAULT_LIGHTNESS_CURVE, 1)).toBeLessThan(0.5);
  });
});
