/**
 * Colour space conversion utilities.
 * hex -> linear sRGB -> XYZ (D65) -> Oklab -> oklch
 * All math follows the official Oklab specification by Björn Ottosson.
 */

export interface OklchColour {
  l: number; // 0-1
  c: number; // 0+ (typically 0-0.4)
  h: number; // 0-360
}

/** Parse a 3, 4, 6, or 8 digit hex string (with or without #) into r,g,b 0-255 */
export function parseHex(hex: string): { r: number; g: number; b: number } | null {
  const clean = hex.replace(/^#/, "");
  let r: number, g: number, b: number;

  if (clean.length === 3 || clean.length === 4) {
    r = parseInt(clean[0]! + clean[0]!, 16);
    g = parseInt(clean[1]! + clean[1]!, 16);
    b = parseInt(clean[2]! + clean[2]!, 16);
  } else if (clean.length === 6 || clean.length === 8) {
    r = parseInt(clean.slice(0, 2), 16);
    g = parseInt(clean.slice(2, 4), 16);
    b = parseInt(clean.slice(4, 6), 16);
  } else {
    return null;
  }

  if (isNaN(r) || isNaN(g) || isNaN(b)) return null;
  return { r, g, b };
}

/** sRGB component (0-1) to linear light */
function toLinear(c: number): number {
  return c <= 0.04045 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4);
}

/** Linear sRGB -> XYZ D65 */
function linearToXyz(r: number, g: number, b: number): [number, number, number] {
  const x = 0.4124564 * r + 0.3575761 * g + 0.1804375 * b;
  const y = 0.2126729 * r + 0.7151522 * g + 0.072175 * b;
  const z = 0.0193339 * r + 0.119192 * g + 0.9503041 * b;
  return [x, y, z];
}

/** XYZ D65 -> Oklab */
function xyzToOklab(x: number, y: number, z: number): [number, number, number] {
  const l = Math.cbrt(0.8189330101 * x + 0.3618667424 * y - 0.1288597137 * z);
  const m = Math.cbrt(0.0329845436 * x + 0.9293118715 * y + 0.0361456387 * z);
  const s = Math.cbrt(0.0482003018 * x + 0.2643662691 * y + 0.633851707 * z);

  return [
    0.2104542553 * l + 0.793617785 * m - 0.0040720468 * s,
    1.9779984951 * l - 2.428592205 * m + 0.4505937099 * s,
    0.0259040371 * l + 0.7827717662 * m - 0.808675766 * s,
  ];
}

/** Convert a hex string to oklch */
export function hexToOklch(hex: string): OklchColour | null {
  const rgb = parseHex(hex);
  if (!rgb) return null;

  const r = toLinear(rgb.r / 255);
  const g = toLinear(rgb.g / 255);
  const b = toLinear(rgb.b / 255);

  const [x, y, z] = linearToXyz(r, g, b);
  const [L, a, bLab] = xyzToOklab(x, y, z);

  const c = Math.sqrt(a * a + bLab * bLab);
  let h = (Math.atan2(bLab, a) * 180) / Math.PI;
  if (h < 0) h += 360;

  return { l: Math.max(0, Math.min(1, L)), c, h };
}

/** Round oklch values to reasonable precision for display */
export function roundOklch(colour: OklchColour): OklchColour {
  return {
    l: Math.round(colour.l * 10000) / 10000,
    c: Math.round(colour.c * 10000) / 10000,
    h: Math.round(colour.h * 10) / 10,
  };
}
