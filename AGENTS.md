# AGENTS.md

## Stack

Ember Octane app using Embroider + Vite. TypeScript with Glint for template type-checking.
Components use `.gts` (Glimmer TypeScript) files with `<template>` tag syntax.
Tests run in-browser via Vitest + `@vitest/browser` (Chromium via Playwright or Preview provider).

## Toolchain versions

Pinned via `.prototools` (proto toolchain manager):

- Node: 25.9.0
- pnpm: 10.33.2

## Key commands

```sh
pnpm dev           # dev server
pnpm build         # production build
pnpm test          # run vitest (in-browser, Chromium); watch mode locally, run-once in CI
pnpm test:ci       # vitest run (non-watch, for CI)
pnpm lint          # eslint + prettier check + tsc (all in parallel)
pnpm lint:fix      # auto-fix eslint + prettier
pnpm lint:types    # ember-tsc --noEmit (uses Glint, not plain tsc)
```

CI runs `pnpm lint` then `pnpm test` in separate jobs.

## Module resolution

Package imports use subpath imports (`#app/*`, `#components/*`, `#services/*`, `#utils/*`, `#config`, `#test-helpers/*`) defined in `package.json` `imports`. Use these instead of relative paths where applicable.

- `#test-helpers/*` maps to `tests/helpers/*` -- that directory does not exist by default; create it if needed.

## App structure

- `app/app.ts` - Application class; registers modules via `import.meta.glob`. New directories (services, templates) must be added here.
- `app/config.ts` - Env config; exports `enterTestMode()` which sets `locationType: "none"` and disables autoboot.
- `app/router.ts` - Route map.
- `app/templates/` - Route templates (`.gts` files).

## Adding services

Due to Embroider not supporting app-tree merging from libraries, services from addons are not auto-discovered. See comment in `app/app.ts` for alternatives (ember-polaris-service or ember-primitives createService).

New local services go in `app/services/` and are auto-picked up by the `import.meta.glob` in `app/app.ts`.

## Type-checking

Use `pnpm lint:types` (wraps `ember-tsc`, which is Glint-aware). Do not run `tsc` directly -- it will miss template type errors.

## Formatting

Prettier with `prettier-plugin-ember-template-tag` (handles `.gts`/`.gjs` files). Print width: 100.

## Testing notes

- Tests live in `tests/**/*.test.{gjs,gts}` (configured in `vite.config.mjs`).
- Vitest runs in-browser via `@vitest/browser-preview` locally and `@vitest/browser-playwright` in CI (headless). No build step needed before running tests.
- The provider switches automatically: `CI=true` in the environment selects Playwright (headless); otherwise preview provider is used.
- `maxConcurrency: 1` is set in `vite.config.mjs`; tests run serially.
- use `pnpm test:ci` to run tests whilst developing

### Running a single test

Pass arguments to vitest via `pnpm test:ci --`, not by invoking vitest directly:

```sh
# Run one file
pnpm test:ci -- tests/components/button.test.gts

# Run tests matching a name pattern
pnpm test:ci -- -t "button renders"
```

### Rendering tests vs acceptance tests

**Rendering tests** render a single component in isolation using `setupRenderingContext` from `ember-vitest`. Use these for components and most logic. See `tests/test.test.gts` for the pattern.

**Acceptance tests** boot the real app via Playwright. Use these only for full route transitions and URL behaviour. They live in `tests/` alongside rendering tests but drive the dev server directly.

## Routing

Lazy route bundles are the intended pattern for code-splitting. The mechanism is via `_embroiderRouteBundles_` -- see the commented-out example in `app/router.ts` for the shape. Each bundle maps a route name to dynamic imports of its template, route, and controller files.

## Styling

- Global styles go in `app/styles/` (import from the template or app entry point as needed).
- Component-scoped styles use CSS modules: `alert.module.css` imported into `alert.gts`.
- Both approaches can coexist; use global styles for tokens/resets and CSS modules for component styles.

## Deployment

`pnpm build` outputs to `dist/`. The app deploys to GitHub Pages at `/huecss/`.

Both `rootURL` in `app/config.ts` and `base` in `vite.config.mjs` are set to `/huecss/` and must stay in sync. A `removeCrossOrigin` Vite plugin strips the `crossorigin` attribute from script tags, which is required for GitHub Pages compatibility.

## Writing components

- Use `.gts` files with `<template>` tag syntax.
- Do not use `@ts-ignore` in component code; fix the underlying type error.
- Use nested component directories for related components (e.g. `app/components/alert/alert.gts`, `app/components/alert/alert-header.gts`).
- Use `#components/*` imports for sibling components (e.g. `import AlertHeader from "#components/alert/alert-header"`).
- Use CSS modules for component styles (e.g. `alert.module.css` imported into `alert.gts`).
