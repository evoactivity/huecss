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

/**
 * Interpolate all 11 tones from user anchors + implicit bezier endpoints.
 *
 * The bezier curves always define tone 50 and tone 950 as implicit endpoints.
 * User anchors override any tone they sit on and are interpolated between.
 * If the user has set tone 50 or 950 explicitly those override the bezier.
 */
export function interpolateRamp(
  anchors: ToneAnchor[],
  definition: ColourDefinition,
  mode: InterpolationMode,
  lightnessCurve: BezierCurve,
  chromaCurve: BezierCurve,
): ColourToken[] {
  // Implicit endpoints from curves -- always present unless the user has
  // explicitly removed those anchors (in which case the anchors array won't
  // contain them and the ramp interpolates freely between what remains).
  const implicit50 = colourFromCurve(50, definition, lightnessCurve, chromaCurve);
  const implicit950 = colourFromCurve(950, definition, lightnessCurve, chromaCurve);

  const hasAnchorAt = (tone: number) => anchors.some((a) => a.tone === tone);

  // Always include tone 50 and 950 as implicit endpoints unless the user has
  // placed their own anchors there. Tone 500 is only included implicitly when
  // the user hasn't explicitly removed it -- we detect removal by checking
  // whether any anchor sits at 500 OR whether the anchors array has anchors on
  // both sides of 500 (meaning 500 was removed and the ramp should interpolate
  // freely through it).
  const userAnchors = [...anchors].sort((a, b) => a.tone - b.tone);

  const scalePoints: Array<{ tone: number; l: number; c: number; h: number }> = [
    hasAnchorAt(50) ? null : { tone: 50, ...implicit50 },
    ...userAnchors,
    hasAnchorAt(950) ? null : { tone: 950, ...implicit950 },
  ]
    .filter((p): p is { tone: number; l: number; c: number; h: number } => p !== null)
    .sort((a, b) => a.tone - b.tone);

  const colours = scalePoints.map((a) => chroma.oklch(a.l, a.c, a.h));
  const domain = scalePoints.map((a) => toneToX(a.tone));

  const scale = chroma.scale(colours).mode(mode).domain(domain);

  return TONES.map((tone) => {
    const x = toneToX(tone);
    const col = scale(x).oklch();
    const l = round(Math.max(0, Math.min(1, col[0])), 4);
    const c = round(Math.max(0, col[1]), 4);
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
