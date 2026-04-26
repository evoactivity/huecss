/**
 * A curve made of two cubic bezier segments joined at a fixed midpoint anchor.
 *
 * The x-axis represents tone position (0 = tone 50, 1 = tone 950).
 * The y-axis is normalised: ANCHOR_Y (0.5) = the colour's 500-tone value.
 * Tone 500 is always fixed at (ANCHOR_X, ANCHOR_Y).
 *
 * Segment 1 (left):  cubic from (0, p0y)      to (0.5, 0.5) with handles cp0 and cpa0
 * Segment 2 (right): cubic from (0.5, 0.5)    to (1, p1y)   with handles cpa1 and cp1
 *
 *   p0 --[cp0]--..--[cpa0]-- anchor --[cpa1]--..--[cp1]-- p1
 */
export interface BezierCurve {
  p0y: number; // y of start point (x always 0)
  cp0x: number; // x of handle near p0 (left segment, first handle)
  cp0y: number; // y of handle near p0
  cpa0x: number; // x of handle near anchor, left side (x <= 0.5)
  cpa0y: number; // y of handle near anchor, left side
  cpa1x: number; // x of handle near anchor, right side (x >= 0.5)
  cpa1y: number; // y of handle near anchor, right side
  cp1x: number; // x of handle near p1 (right segment, second handle)
  cp1y: number; // y of handle near p1
  p1y: number; // y of end point (x always 1)
}

export const ANCHOR_X = 0.5;
export const ANCHOR_Y = 0.5;

/** Evaluate a cubic bezier at parameter t */
function cubic(p0: number, cp0: number, cp1: number, p1: number, t: number): number {
  const mt = 1 - t;
  return mt * mt * mt * p0 + 3 * mt * mt * t * cp0 + 3 * mt * t * t * cp1 + t * t * t * p1;
}

function cubicX(p0x: number, cp0x: number, cp1x: number, p1x: number, t: number): number {
  return cubic(p0x, cp0x, cp1x, p1x, t);
}

function findT(p0x: number, cp0x: number, cp1x: number, p1x: number, targetX: number): number {
  let lo = 0,
    hi = 1;
  for (let i = 0; i < 32; i++) {
    const mid = (lo + hi) / 2;
    const bx = cubicX(p0x, cp0x, cp1x, p1x, mid);
    if (Math.abs(bx - targetX) < 1e-6) return mid;
    if (bx < targetX) lo = mid;
    else hi = mid;
  }
  return (lo + hi) / 2;
}

/**
 * Evaluate the two-segment curve at a given x position (0-1).
 * Always returns ANCHOR_Y at x = ANCHOR_X.
 */
export function evaluateBezier(curve: BezierCurve, x: number): number {
  if (x <= 0) return curve.p0y;
  if (x >= 1) return curve.p1y;
  if (x === ANCHOR_X) return ANCHOR_Y;

  if (x < ANCHOR_X) {
    const t = findT(0, curve.cp0x, curve.cpa0x, ANCHOR_X, x);
    return cubic(curve.p0y, curve.cp0y, curve.cpa0y, ANCHOR_Y, t);
  } else {
    const t = findT(ANCHOR_X, curve.cpa1x, curve.cp1x, 1, x);
    return cubic(ANCHOR_Y, curve.cpa1y, curve.cp1y, curve.p1y, t);
  }
}

/**
 * Produce the SVG path d attribute for the two-segment cubic curve.
 */
export function bezierSvgPath(
  curve: BezierCurve,
  svgW: number,
  svgH: number,
  padding: number,
): string {
  const w = svgW - 2 * padding;
  const h = svgH - 2 * padding;
  const sx = (x: number) => padding + x * w;
  const sy = (y: number) => padding + (1 - y) * h;

  return [
    `M${sx(0)},${sy(curve.p0y)}`,
    `C${sx(curve.cp0x)},${sy(curve.cp0y)} ${sx(curve.cpa0x)},${sy(curve.cpa0y)} ${sx(ANCHOR_X)},${sy(ANCHOR_Y)}`,
    `C${sx(curve.cpa1x)},${sy(curve.cpa1y)} ${sx(curve.cp1x)},${sy(curve.cp1y)} ${sx(1)},${sy(curve.p1y)}`,
  ].join(" ");
}

/** Map a tone number (50-950) to a normalised x position (0-1) */
export function toneToX(tone: number): number {
  return (tone - 50) / 900;
}

export const DEFAULT_LIGHTNESS_CURVE: BezierCurve = {
  p0y: 0.9,
  cp0x: 0.15,
  cp0y: 0.85,
  cpa0x: 0.35,
  cpa0y: 0.6,
  cpa1x: 0.65,
  cpa1y: 0.4,
  cp1x: 0.85,
  cp1y: 0.15,
  p1y: 0.08,
};

export const DEFAULT_CHROMA_CURVE: BezierCurve = {
  p0y: 0.05,
  cp0x: 0.15,
  cp0y: 0.2,
  cpa0x: 0.35,
  cpa0y: 0.45,
  cpa1x: 0.65,
  cpa1y: 0.45,
  cp1x: 0.85,
  cp1y: 0.25,
  p1y: 0.15,
};
