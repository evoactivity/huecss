import { trackedArray, trackedObject } from "@ember/reactive/collections";
import type { ColourDefinition, Tone } from "#utils/colours";
import type { BezierCurve } from "#utils/spline";
import { interpolateRamp, colourFromCurve, makeAnchor } from "#utils/interpolate";
import type { ToneAnchor, InterpolationMode } from "#utils/interpolate";
import { DEFAULT_LIGHTNESS_CURVE, DEFAULT_CHROMA_CURVE } from "#utils/spline";

export type { ToneAnchor, InterpolationMode };

export interface CurveOverride {
  lightness?: BezierCurve;
  chroma?: BezierCurve;
}

export interface ActiveColour {
  definition: ColourDefinition;
  /** User-placed anchors only -- empty on activation */
  anchors: ToneAnchor[];
  /** Colour space used for chroma.js interpolation */
  interpolationMode: InterpolationMode;
  /** Optional bezier overrides */
  curveOverride?: CurveOverride;
}

export interface ColourToken {
  name: string;
  tone: Tone;
  variable: string;
  value: string;
  l: number;
  c: number;
  h: number;
}

export interface GlobalCurves {
  lightness: BezierCurve;
  chroma: BezierCurve;
}

export const DEFAULT_GLOBAL_CURVES: GlobalCurves = {
  lightness: DEFAULT_LIGHTNESS_CURVE,
  chroma: DEFAULT_CHROMA_CURVE,
};

export const DEFAULT_INTERPOLATION_MODE: InterpolationMode = "oklch";

/**
 * Derive the effective bezier curves for a colour:
 * user override → colour's own fitted curves → global defaults
 */
export function effectiveCurves(
  active: ActiveColour,
  globalCurves: GlobalCurves = DEFAULT_GLOBAL_CURVES,
): { lightness: BezierCurve; chroma: BezierCurve } {
  return {
    lightness:
      active.curveOverride?.lightness ?? active.definition.lightnessCurve ?? globalCurves.lightness,
    chroma: active.curveOverride?.chroma ?? active.definition.chromaCurve ?? globalCurves.chroma,
  };
}

/**
 * Activate a colour with no anchors. The bezier curves define the ramp shape;
 * the user adds anchors to override specific tones.
 */
export function activateColour(
  definition: ColourDefinition,
  interpolationMode: InterpolationMode = DEFAULT_INTERPOLATION_MODE,
): ActiveColour {
  const lightnessCurve = definition.lightnessCurve ?? DEFAULT_LIGHTNESS_CURVE;
  const chromaCurve = definition.chromaCurve ?? DEFAULT_CHROMA_CURVE;

  const tone50 = colourFromCurve(50, definition, lightnessCurve, chromaCurve);
  const tone950 = colourFromCurve(950, definition, lightnessCurve, chromaCurve);

  return trackedObject({
    definition,
    anchors: trackedArray([
      makeAnchor(50, tone50.l, tone50.c, tone50.h),
      makeAnchor(500, definition.lightness, definition.chroma, definition.hue),
      makeAnchor(950, tone950.l, tone950.c, tone950.h),
    ]),
    interpolationMode,
    curveOverride: undefined,
  });
}

/**
 * Generate all colour tokens. Bezier curves provide implicit endpoints;
 * user anchors are interpolated between them.
 */
export function generateTokens(activeColours: ActiveColour[]): ColourToken[] {
  return activeColours.flatMap((active) => {
    const { lightness, chroma } = effectiveCurves(active);
    return interpolateRamp(
      active.anchors,
      active.definition,
      active.interpolationMode,
      lightness,
      chroma,
    );
  });
}
