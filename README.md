# huecss

A browser-based studio for designing OKLCH colour ramps and exporting them as CSS custom properties. Live at [huecss.dev](https://huecss.dev/).

## What it does

Pick from 26 Tailwind v4 inspired ramps or define your own. Lock the tones you care about, let the rest interpolate, and copy the result straight into your project.

- **Anchor-based ramps.** Each ramp generates 11 tones (50 through 950). Anchor any tone to lock it, the others interpolate between anchors.
- **Direct OKLCH editing.** Edit anchors with a hue wheel, lightness and chroma sliders, or by typing any CSS colour string (`oklch(...)`, `#hex`, `rgb(...)`, named colours, etc).
- **Bezier-shaped curves.** Each built-in ramp ships with curves fit to the Tailwind v4 palette so the defaults look familiar. Custom colours fall back to a generic curve shape until you start anchoring.
- **CSS export.** Tokens render as `--color-{name}-{tone}` custom properties using `oklch(...)` values, ready to paste into your stylesheet.

## Running locally

Toolchain versions are pinned via `.prototools` (proto):

- Node 25.9.0
- pnpm 10.33.2

```sh
pnpm install
pnpm dev          # dev server
pnpm build        # production build to dist/
pnpm test         # run tests in browser via Vitest, watch mode
pnpm test:ci      # tests, single run
pnpm lint         # eslint + prettier + ember-tsc, in parallel
pnpm lint:fix     # auto-fix what can be auto-fixed
```

## How interpolation works

Ramps are interpolated **directly in OKLCH** rather than going through chroma-js's RGB-backed colour scale. This matters for two reasons:

1. **Anchors round-trip exactly.** If you set tone 500 to `oklch(63.7% 0.237 221.8)`, the generated CSS reads back the same values, even when the colour is outside the sRGB gamut. Browsers will gamut-map at render time, but the source of truth stays honest.
2. **Hue takes the shorter arc.** Between two chromatic anchors hue follows the short way around the wheel. When one neighbour is achromatic (chroma ≈ 0) hue is meaningless on that side, so it inherits the chromatic neighbour's hue rather than drifting through grey.

The default ramp shape comes from two cubic bezier curves per colour, one for lightness and one for chroma, fit to the Tailwind v4 OKLCH palette. The curves provide the implicit endpoints at tone 50 and 950, the user provides anchors anywhere they want, and the OKLCH lerp connects the dots.

See `app/utils/interpolate.ts` for the interpolator and `app/utils/spline.ts` for the bezier curves.

## Tech stack

Ember with Vite. TypeScript with Glint for template type-checking. Components are `.gts` files using `<template>` tag syntax. Tests run in the browser via `@vitest/browser` (preview provider locally, Playwright headless in CI).

The studio state lives in a single `colour-studio` service (`app/services/colour-studio.ts`). The route template (`app/templates/index.gts`) is a thin shell, the interesting logic is in `RampEditor`, `TonePicker`, and `interpolateRamp`.

## Static site generation

`pnpm build` runs the `vite-ember-ssr` plugin (`emberSsg`) over the route list (`routes: ["index"]` in `vite.config.mjs`). For each route the plugin renders the Ember app to HTML at build time and writes a static page into `dist/`. GitHub Pages serves the result.

On the client, `app/entry.ts` checks `shouldRehydrate()`. When the page was prerendered the app boots in rehydrate mode and reuses the existing DOM, when not it falls back to a normal client-side boot. From the user's perspective the first paint is immediate (just static HTML), and once the JS bundle loads the page becomes a normal interactive Ember app without re-rendering.

Adding a new prerendered route means listing it in the `emberSsg` config's `routes` array. Routes that should stay client-only can be left out.

## Project layout

```
app/
  components/         <- .gts components, one folder each
  services/           <- colour-studio service
  templates/          <- route templates
  utils/              <- pure logic: colours, interpolate, css-output, spline
  styles/             <- global tokens and resets
tests/                <- vitest specs alongside the units they cover
scripts/              <- one-off scripts (e.g. fitting bezier curves to Tailwind)
```

Subpath imports (`#app/*`, `#components/*`, `#services/*`, `#utils/*`, `#config`) are defined in `package.json` and should be preferred over relative paths.

## Contributing

See [`CONTRIBUTING.md`](./CONTRIBUTING.md) for setup, project layout, conventions, and PR guidance. `AGENTS.md` covers the same ground in the form expected by code agents.

## License

MIT
