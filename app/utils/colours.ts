// Base colour definitions. Each entry defines the exact oklch values at the
// 500 tone. These are the ground truth -- tone 500 will always render exactly
// these values regardless of curve shape. Curves control the ramp either side.
// Values sourced from the Tailwind CSS v4 oklch palette.

export interface ColourDefinition {
  name: string;
  /** Lightness at tone 500 (0-1) */
  lightness: number;
  /** Chroma at tone 500 */
  chroma: number;
  /** Hue angle (0-360) */
  hue: number;
}

export const DEFAULT_COLOURS: ColourDefinition[] = [
  { name: "red", lightness: 0.577, chroma: 0.245, hue: 27.325 },
  { name: "orange", lightness: 0.702, chroma: 0.191, hue: 50.872 },
  { name: "amber", lightness: 0.769, chroma: 0.188, hue: 75.652 },
  { name: "yellow", lightness: 0.852, chroma: 0.199, hue: 95.391 },
  { name: "lime", lightness: 0.768, chroma: 0.233, hue: 131.843 },
  { name: "green", lightness: 0.723, chroma: 0.219, hue: 149.579 },
  { name: "emerald", lightness: 0.696, chroma: 0.195, hue: 162.48 },
  { name: "teal", lightness: 0.704, chroma: 0.14, hue: 180.335 },
  { name: "cyan", lightness: 0.715, chroma: 0.143, hue: 200.556 },
  { name: "sky", lightness: 0.685, chroma: 0.169, hue: 212.077 },
  { name: "blue", lightness: 0.546, chroma: 0.245, hue: 264.052 },
  { name: "indigo", lightness: 0.511, chroma: 0.262, hue: 282.849 },
  { name: "violet", lightness: 0.541, chroma: 0.281, hue: 293.541 },
  { name: "purple", lightness: 0.558, chroma: 0.288, hue: 309.193 },
  { name: "fuchsia", lightness: 0.584, chroma: 0.289, hue: 322.15 },
  { name: "pink", lightness: 0.656, chroma: 0.241, hue: 350.252 },
  { name: "rose", lightness: 0.596, chroma: 0.25, hue: 14.708 },
  { name: "slate", lightness: 0.554, chroma: 0.016, hue: 264.052 },
  { name: "gray", lightness: 0.551, chroma: 0.008, hue: 264.052 },
  { name: "zinc", lightness: 0.552, chroma: 0.006, hue: 286.033 },
  { name: "neutral", lightness: 0.556, chroma: 0, hue: 0 },
  { name: "stone", lightness: 0.553, chroma: 0.013, hue: 50.872 },
  { name: "taupe", lightness: 0.553, chroma: 0.02, hue: 60 },
  { name: "mauve", lightness: 0.553, chroma: 0.02, hue: 300 },
  { name: "mist", lightness: 0.553, chroma: 0.015, hue: 220 },
  { name: "olive", lightness: 0.553, chroma: 0.025, hue: 110 },
];

export const TONES = [50, 100, 200, 300, 400, 500, 600, 700, 800, 900, 950] as const;
export type Tone = (typeof TONES)[number];
