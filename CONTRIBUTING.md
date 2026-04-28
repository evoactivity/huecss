# Contributing

Thanks for taking an interest. This file is for human contributors. The same conventions are also captured in `AGENTS.md` for code agents.

## Getting set up

Versions are pinned in `.prototools` and managed with [proto](https://moonrepo.dev/proto). If you don't use proto, install Node 25.9.0 and pnpm 10.33.2 by hand.

```sh
git clone https://github.com/anomalyco/huecss.git
cd huecss
pnpm install
pnpm dev
```

That's it, no separate build step needed. The dev server hot-reloads on save.

## The commands you'll actually use

```sh
pnpm dev          # dev server
pnpm build        # production build to dist/
pnpm test         # vitest watch mode, runs in your browser
pnpm test:ci      # single run, headless, what CI uses
pnpm lint         # eslint + prettier + ember-tsc, in parallel
pnpm lint:fix     # auto-fix the easy stuff
```

`pnpm lint:types` runs `ember-tsc` on its own. Don't reach for plain `tsc`, it doesn't understand `.gts` template type-checking and will silently miss errors.

To run a single test, pass through to vitest:

```sh
pnpm test:ci -- tests/components/ramp-editor.test.gts
pnpm test:ci -- -t "anchors round-trip"
```

## Where things live

```
app/
  components/   <- one folder per component
  services/     <- the colour-studio service
  templates/    <- route templates
  utils/        <- pure logic: colours, interpolate, css-output, spline
  styles/       <- global tokens and resets
tests/          <- specs alongside what they cover
scripts/        <- one-off scripts (e.g. fitting bezier curves)
```

Use the subpath imports defined in `package.json` (`#components/*`, `#services/*`, `#utils/*`, etc.) instead of relative paths. New top-level directories under `app/` need to be added to the `import.meta.glob` in `app/app.ts` so Embroider picks them up.

## Components

Components are `.gts` files using `<template>` tag syntax. Group related components in a folder, e.g. `app/components/alert/alert.gts` and `app/components/alert/alert-header.gts`. Component-scoped styles go in a CSS module next to the component (`alert.module.css`). Global tokens and resets live in `app/styles/`.

A note on services: Embroider doesn't auto-discover services from addons, so any service you add needs to live in `app/services/` (which `app/app.ts` globs) or be wrapped via `ember-polaris-service` / `ember-primitives` `createService`. There's a comment at the top of `app/app.ts` with the details.

## Tests

Most tests are rendering tests using `setupRenderingContext` from `ember-vitest`. `tests/components/app-header.test.gts` is the smallest example to copy from, `tests/components/ramp-editor.test.gts` shows the same pattern with user interaction. Plain TypeScript modules get unit-tested in `tests/utils/` as `.test.ts` files, see `tests/utils/interpolate.test.ts`.

Tests run in a real browser. Locally that's whatever Chromium you already have via `@vitest/browser-preview`, on CI it's headless Chromium via Playwright. They run serially.

Add tests for new code. Run `pnpm test:ci` before you open a PR.

## Style and formatting

Prettier handles `.gts` and `.gjs` via `prettier-plugin-ember-template-tag`. Print width is 100. `pnpm lint:fix` will sort out anything mechanical. Type errors won't auto-fix, you have to deal with those by hand.

## Working on a branch

Branch off the latest `main` with a short kebab-case name describing what you're doing:

```sh
git fetch origin
git checkout main
git pull
git checkout -b fix-anchor-roundtrip
```

Names like `fix-anchor-roundtrip`, `colour-picker-keyboard-nav`, `add-readme`. Skip the `feat/` and `fix/` prefixes, the project doesn't use them. Don't push to `main`.

Commit messages are in plain English, focused on the why rather than the what. Subject line around 70 characters, body if you need to explain anything a future reader would want context for. Here's a real one from the repo:

```
Interpolate ramps in OKLCH directly so anchors round-trip exactly

Replace chroma.scale with a manual OKLCH lerp in interpolateRamp.
chroma-js stores Color objects internally as RGB and silently gamut
clipped out-of-gamut OKLCH anchors at construction time, which meant
high-chroma user anchors came out of the scale with the wrong values.
```

Try to keep commits self-contained. If you find yourself doing two unrelated things in one commit, split it.

## Opening a PR

Before you open it: rebase or merge `main` in, run `pnpm lint`, run `pnpm test:ci`, make sure new code has tests where it makes sense.

In the PR itself: clear title in the same style as the commit subject, description that explains the motivation and anything reviewers should focus on. Screenshots or a short clip help for visual changes. Mark it as draft if it's not ready.

CI runs lint and tests on every PR. Both have to pass before merge.

## Deployment

`main` deploys to GitHub Pages on every push, served from the custom domain [huecss.dev](https://huecss.dev/). The build prerenders the routes listed in `vite.config.mjs` via `vite-ember-ssr`. `rootURL` in `app/config.ts` and `base` in `vite.config.mjs` are both `/` and need to stay in sync.

## Bugs and questions

Bugs: open an issue with a short title, what you did, what you expected, what happened, and your browser if it's a runtime thing. A repro (sequence of clicks in the studio plus the resulting CSS) is the fastest path to a fix.

Questions: if you're unsure whether a change fits the project, open an issue before you write the code. Easier to redirect a sentence than a 500-line PR.
