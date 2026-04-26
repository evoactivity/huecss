import chroma from "chroma-js";
import { trackedObject } from "@ember/reactive/collections";
import { evaluateBezier, toneToX } from "#utils/spline";
import type { BezierCurve } from "#utils/spline";
import type { ColourDefinition, Tone } from "#utils/colours";
import { TONES } from "#utils/colours";
import type { ColourToken } from "#utils/token-generator";

export type InterpolationMode = "oklch" | "oklab" | "lch" | "lab";

export const INTERPOLATION_MODES: InterpolationMode[] = ["oklch", "oklab", "lch", "lab"];

export interface ToneAnchor {
  tone: Tone;
  l: number;
  c: number;
  h: number;
  /** True if this anchor was seeded from the bezier curve (not user-placed).
   *  Seeded anchors at tone 50 and 950 revert to bezier when removed.
   *  The seeded anchor at tone 500 reverts to the definition value when removed. */
  seeded: boolean;
}

/**
 * Derive the colour at a given tone from a bezier curve + colour definition.
 * Evaluates L and C from the curves (normalised relative to ANCHOR_Y),
 * and uses the definition hue.
 */
function colourFromCurve(
  tone: Tone,
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

/**
 * Seed the initial 3 anchors for a colour from its bezier curves.
 * Tone 50 and 950 come from the bezier; tone 500 comes from the definition.
 */
export function seedAnchors(
  definition: ColourDefinition,
  lightnessCurve: BezierCurve,
  chromaCurve: BezierCurve,
): ToneAnchor[] {
  const tone50 = colourFromCurve(50, definition, lightnessCurve, chromaCurve);
  const tone950 = colourFromCurve(950, definition, lightnessCurve, chromaCurve);

  return [
    trackedObject({ tone: 50, ...tone50, seeded: true }),
    trackedObject({
      tone: 500,
      l: definition.lightness,
      c: definition.chroma,
      h: definition.hue,
      seeded: true,
    }),
    trackedObject({ tone: 950, ...tone950, seeded: true }),
  ];
}

/**
 * Revert a seeded anchor to its default value.
 * Tone 50/950 reverts to bezier-derived value; tone 500 reverts to definition.
 */
export function revertAnchor(
  tone: Tone,
  definition: ColourDefinition,
  lightnessCurve: BezierCurve,
  chromaCurve: BezierCurve,
): ToneAnchor {
  if (tone === 500) {
    return trackedObject({
      tone: 500,
      l: definition.lightness,
      c: definition.chroma,
      h: definition.hue,
      seeded: true,
    });
  }
  return trackedObject({
    tone,
    ...colourFromCurve(tone, definition, lightnessCurve, chromaCurve),
    seeded: true,
  });
}

/**
 * Interpolate all 11 tones from a set of anchors using chroma.js.
 * Anchors must include at least tone 50 and tone 950.
 * Returns ColourToken[] for all TONES.
 */
export function interpolateRamp(
  anchors: ToneAnchor[],
  definition: ColourDefinition,
  mode: InterpolationMode,
): ColourToken[] {
  const sorted = [...anchors].sort((a, b) => a.tone - b.tone);

  // Build chroma scale from anchor colours and their positions (0-1)
  const colours = sorted.map((a) => chroma.oklch(a.l, a.c, a.h));
  const domain = sorted.map((a) => toneToX(a.tone));

  const scale = chroma.scale(colours).mode(mode).domain(domain);

  return TONES.map((tone) => {
    const x = toneToX(tone);
    const col = scale(x).oklch();
    const l = round(Math.max(0, Math.min(1, col[0])), 4);
    const c = round(Math.max(0, col[1]), 4);
    // oklch hue is NaN for achromatic colours -- fall back to definition hue
    const h = round(isNaN(col[2]) ? definition.hue : col[2], 3);

    return {
      name: definition.name,
      tone,
      variable: `--color-${definition.name}-${tone}`,
      value: `${round(l * 100, 2)}% ${c} ${h}`,
      l,
      c,
      h,
    };
  });
}

function round(value: number, decimals: number): number {
  const factor = Math.pow(10, decimals);
  return Math.round(value * factor) / factor;
}
