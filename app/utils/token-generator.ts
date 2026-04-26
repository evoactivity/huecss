import { trackedArray } from "@ember/reactive/collections";
import type { ColourDefinition } from "#utils/colours";
import type { BezierCurve } from "#utils/spline";
import { interpolateRamp, seedAnchors } from "#utils/interpolate";
import type { ToneAnchor, InterpolationMode } from "#utils/interpolate";
import { DEFAULT_LIGHTNESS_CURVE, DEFAULT_CHROMA_CURVE } from "#utils/spline";

export type { ToneAnchor, InterpolationMode };

export interface CurveOverride {
  lightness?: BezierCurve;
  chroma?: BezierCurve;
}

export interface ActiveColour {
  definition: ColourDefinition;
  /** Always present -- seeded on activation from bezier curves */
  anchors: ToneAnchor[];
  /** Colour space used for chroma.js interpolation */
  interpolationMode: InterpolationMode;
  /** Optional bezier overrides that shape the seeded tone 50/950 anchors */
  curveOverride?: CurveOverride;
}

export interface ColourToken {
  name: string;
  tone: import("#utils/colours").Tone;
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
 * Seed a fresh ActiveColour from a definition.
 * Always called when a colour is first activated.
 */
export function activateColour(
  definition: ColourDefinition,
  globalCurves: GlobalCurves = DEFAULT_GLOBAL_CURVES,
  interpolationMode: InterpolationMode = DEFAULT_INTERPOLATION_MODE,
): ActiveColour {
  const lightnessCurve = definition.lightnessCurve ?? globalCurves.lightness;
  const chromaCurve = definition.chromaCurve ?? globalCurves.chroma;

  return {
    definition,
    anchors: trackedArray(seedAnchors(definition, lightnessCurve, chromaCurve)),
    interpolationMode,
  };
}

/**
 * Generate all colour tokens for the given active colours.
 * Always uses chroma.js interpolation through the colour's anchors.
 */
export function generateTokens(activeColours: ActiveColour[]): ColourToken[] {
  return activeColours.flatMap((active) =>
    interpolateRamp(active.anchors, active.definition, active.interpolationMode),
  );
}
