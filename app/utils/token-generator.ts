import type { ColourDefinition, Tone } from "#utils/colours";
import { TONES } from "#utils/colours";
import {
  evaluateBezier,
  toneToX,
  DEFAULT_LIGHTNESS_CURVE,
  DEFAULT_CHROMA_CURVE,
} from "#utils/spline";
import type { BezierCurve } from "#utils/spline";

export interface CurveOverride {
  lightness?: BezierCurve;
  chroma?: BezierCurve;
}

export interface ActiveColour {
  definition: ColourDefinition;
  /** Optional per-colour curve overrides; falls back to global curves when absent */
  curveOverride?: CurveOverride;
}

export interface ColourToken {
  /** e.g. "blue" */
  name: string;
  /** e.g. 500 */
  tone: Tone;
  /** CSS variable name, e.g. "--color-blue-500" */
  variable: string;
  /** oklch value string, e.g. "0.577 0.232 264.052" */
  value: string;
  /** Raw oklch channels for rendering swatches */
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

// x position of tone 500 -- the anchor point
const X_500 = toneToX(500);

/**
 * Generate all colour tokens for the given active colours.
 *
 * Tone 500 is the ground truth: it always renders exactly the definition's
 * lightness and chroma. The curves are used as a relative ramp -- each curve
 * value is divided by the curve's value at x=0.5 (tone 500) to produce a
 * normalised multiplier, which is then applied to the 500-tone anchor value.
 *
 * This means editing the curve shape never shifts tone 500.
 */
export function generateTokens(
  activeColours: ActiveColour[],
  globalCurves: GlobalCurves = DEFAULT_GLOBAL_CURVES,
): ColourToken[] {
  const tokens: ColourToken[] = [];

  for (const active of activeColours) {
    const { definition, curveOverride } = active;
    // Priority: user per-colour override → colour's own fitted curve → global default
    const lightnessCurve =
      curveOverride?.lightness ?? definition.lightnessCurve ?? globalCurves.lightness;
    const chromaCurve = curveOverride?.chroma ?? definition.chromaCurve ?? globalCurves.chroma;

    // Evaluate curves at tone 500 to use as the normalisation anchor
    const lAnchor = evaluateBezier(lightnessCurve, X_500);
    const cAnchor = evaluateBezier(chromaCurve, X_500);

    for (const tone of TONES) {
      const x = toneToX(tone);

      // Normalise: scale curve output so the 500 tone always equals the definition value
      const lRaw =
        lAnchor > 0
          ? (evaluateBezier(lightnessCurve, x) / lAnchor) * definition.lightness
          : definition.lightness;
      const cRaw =
        cAnchor > 0
          ? (evaluateBezier(chromaCurve, x) / cAnchor) * definition.chroma
          : definition.chroma;

      const l = round(clamp(lRaw, 0, 1), 4);
      const c = round(Math.max(0, cRaw), 4);
      const h = round(definition.hue, 3);

      tokens.push({
        name: definition.name,
        tone,
        variable: `--color-${definition.name}-${tone}`,
        value: `${l} ${c} ${h}`,
        l,
        c,
        h,
      });
    }
  }

  return tokens;
}

function clamp(value: number, min: number, max: number): number {
  return Math.min(max, Math.max(min, value));
}

function round(value: number, decimals: number): number {
  const factor = Math.pow(10, decimals);
  return Math.round(value * factor) / factor;
}
