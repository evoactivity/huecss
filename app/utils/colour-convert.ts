import chroma from "chroma-js";

export interface OklchColour {
  l: number; // 0-1
  c: number; // 0+ (typically 0-0.4)
  h: number; // 0-360
}

/** Convert a hex string to oklch. Returns null if the input cannot be parsed. */
export function hexToOklch(hex: string): OklchColour | null {
  if (!chroma.valid(hex)) return null;
  const [l, c, h] = chroma(hex).oklch();
  return {
    l: Math.max(0, Math.min(1, l)),
    c: Math.max(0, c),
    // atan2 can return NaN for achromatic colours -- default to 0
    h: isNaN(h) ? 0 : h,
  };
}

/** Round oklch values to reasonable precision for display */
export function roundOklch(colour: OklchColour): OklchColour {
  return {
    l: Math.round(colour.l * 10000) / 10000,
    c: Math.round(colour.c * 10000) / 10000,
    h: Math.round(colour.h * 10) / 10,
  };
}
