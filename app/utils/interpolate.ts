import { trackedObject } from "@ember/reactive/collections";
import { evaluateBezier, toneToX } from "#utils/spline";
import type { BezierCurve } from "#utils/spline";
import type { ColourDefinition, Tone } from "#utils/colours";
import { TONES } from "#utils/colours";
import type { ColourToken } from "#utils/token-generator";

export interface ToneAnchor {
  tone: Tone;
  l: number;
  c: number;
  h: number;
}

interface ScalePoint {
  tone: number;
  l: number;
  c: number;
  h: number;
}

/**
 * Derive the colour at a given tone from a bezier curve + colour definition.
 * Evaluates L and C from the curves (normalised relative to ANCHOR_Y),
 * and uses the definition hue.
 */
export function colourFromCurve(
  tone: number,
  definition: ColourDefinition,
  lightnessCurve: BezierCurve,
  chromaCurve: BezierCurve,
): { l: number; c: number; h: number } {
  const x = toneToX(tone);
  const lAnchor = evaluateBezier(lightnessCurve, toneToX(500));
  const cAnchor = evaluateBezier(chromaCurve, toneToX(500));

  const l =
    lAnchor > 0
      ? Math.min(
          1,
          Math.max(0, (evaluateBezier(lightnessCurve, x) / lAnchor) * definition.lightness),
        )
      : definition.lightness;

  const cScale =
    cAnchor > 0 ? Math.min(1, Math.max(0, evaluateBezier(chromaCurve, x) / cAnchor)) : 1;
  const c = Math.max(0, cScale * definition.chroma);

  return { l, c, h: definition.hue };
}

/** Create a new tracked anchor object */
export function makeAnchor(tone: Tone, l: number, c: number, h: number): ToneAnchor {
  return trackedObject({ tone, l, c, h });
}

/** Linearly interpolate between two scalars. */
function lerp(a: number, b: number, t: number): number {
  return a + (b - a) * t;
}

/**
 * Interpolate hue on the 0..360 circle taking the shorter arc. When one
 * side is achromatic (c ≈ 0) hue is meaningless there, so we inherit the
 * other side's hue to avoid drifting through the wrong half of the wheel.
 */
function lerpHue(h1: number, c1: number, h2: number, c2: number, t: number): number {
  const ACHROMATIC = 1e-4;
  if (c1 < ACHROMATIC && c2 < ACHROMATIC) return h1;
  if (c1 < ACHROMATIC) return h2;
  if (c2 < ACHROMATIC) return h1;

  // Normalise hues to [0, 360) before measuring arc length.
  const a = ((h1 % 360) + 360) % 360;
  const b = ((h2 % 360) + 360) % 360;
  let delta = b - a;
  if (delta > 180) delta -= 360;
  else if (delta < -180) delta += 360;
  const result = a + delta * t;
  return ((result % 360) + 360) % 360;
}

/**
 * Interpolate all 11 tones from user anchors and the implicit bezier
 * endpoints. The interpolation runs in OKLCH directly so anchors round
 * trip exactly (no gamut clipping along the way).
 *
 * The bezier curves always define tone 50 and tone 950 as implicit
 * endpoints unless the user has placed their own anchors there.
 */
export function interpolateRamp(
  anchors: ToneAnchor[],
  definition: ColourDefinition,
  lightnessCurve: BezierCurve,
  chromaCurve: BezierCurve,
): ColourToken[] {
  const implicit50 = colourFromCurve(50, definition, lightnessCurve, chromaCurve);
  const implicit950 = colourFromCurve(950, definition, lightnessCurve, chromaCurve);

  const hasAnchorAt = (tone: number) => anchors.some((a) => a.tone === tone);
  const userAnchors = [...anchors].sort((a, b) => a.tone - b.tone);

  const scalePoints: ScalePoint[] = [
    hasAnchorAt(50) ? null : { tone: 50, ...implicit50 },
    ...userAnchors,
    hasAnchorAt(950) ? null : { tone: 950, ...implicit950 },
  ]
    .filter((p): p is ScalePoint => p !== null)
    .sort((a, b) => a.tone - b.tone);

  return TONES.map((tone) => {
    const sample = sampleAt(tone, scalePoints, definition);
    return toToken(definition, tone, sample.l, sample.c, sample.h);
  });
}

/**
 * Find the bracketing anchor pair for a tone and lerp between them in
 * OKLCH. If the tone sits exactly on an anchor we return that anchor's
 * values verbatim (this is the round-trip guarantee).
 */
function sampleAt(
  tone: number,
  scalePoints: ScalePoint[],
  definition: ColourDefinition,
): { l: number; c: number; h: number } {
  if (scalePoints.length === 0) {
    return { l: definition.lightness, c: definition.chroma, h: definition.hue };
  }

  if (scalePoints.length === 1) {
    const only = scalePoints[0]!;
    return { l: only.l, c: only.c, h: only.h };
  }

  // Outside the anchor range: clamp to the nearest endpoint.
  const first = scalePoints[0]!;
  const last = scalePoints[scalePoints.length - 1]!;
  if (tone <= first.tone) return { l: first.l, c: first.c, h: first.h };
  if (tone >= last.tone) return { l: last.l, c: last.c, h: last.h };

  // Find bracketing pair.
  for (let i = 0; i < scalePoints.length - 1; i++) {
    const left = scalePoints[i]!;
    const right = scalePoints[i + 1]!;
    if (tone === left.tone) return { l: left.l, c: left.c, h: left.h };
    if (tone === right.tone) return { l: right.l, c: right.c, h: right.h };
    if (tone > left.tone && tone < right.tone) {
      const t = (tone - left.tone) / (right.tone - left.tone);
      return {
        l: lerp(left.l, right.l, t),
        c: lerp(left.c, right.c, t),
        h: lerpHue(left.h, left.c, right.h, right.c, t),
      };
    }
  }

  // Should be unreachable -- fall back to the last anchor.
  return { l: last.l, c: last.c, h: last.h };
}

function toToken(
  definition: ColourDefinition,
  tone: Tone,
  l: number,
  c: number,
  h: number,
): ColourToken {
  const lr = round(Math.min(1, Math.max(0, l)), 4);
  const cr = round(Math.max(0, c), 4);
  const hr = round(((h % 360) + 360) % 360, 3);
  return {
    name: definition.name,
    tone,
    variable: `--color-${definition.name}-${tone}`,
    value: `${round(lr * 100, 2)}% ${cr} ${hr}`,
    l: lr,
    c: cr,
    h: hr,
  };
}

function round(value: number, decimals: number): number {
  const factor = Math.pow(10, decimals);
  return Math.round(value * factor) / factor;
}
