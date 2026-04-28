import { defineConfig } from "vite";
import { extensions, ember } from "@embroider/vite";
import { babel } from "@rollup/plugin-babel";
import { preview } from "@vitest/browser-preview";
import { playwright } from "@vitest/browser-playwright";
import { patchCssModules } from "vite-css-modules";
import { emberSsg } from "vite-ember-ssr/vite-plugin";
import svgJar from "@svg-jar/plugin/vite";

const isCI = process.env.CI === "true";

function removeCrossOrigin() {
  return {
    name: "remove-crossorigin",
    transformIndexHtml(html) {
      return html.replace(/ crossorigin /g, " ");
    },
  };
}

export default defineConfig(({ command }) => ({
  base: "/",
  css: {
    modules: {
      localsConvention: "camelCaseOnly",
    },
  },
  optimizeDeps: {
    include: ["ember-source/@ember/service/index.js", "@embroider/router"],
  },
  test: {
    include: ["tests/**/*.test.{gjs,gts,ts}"],
    maxConcurrency: 1,
    browser: {
      provider: isCI ? playwright() : preview(),
      enabled: true,
      headless: isCI,
      instances: [{ browser: "chromium" }],
      // Don't write a PNG on every failed assertion, the failure message
      // already tells us what we need and the files clutter the tree.
      screenshotFailures: false,
    },
  },
  plugins: [
    patchCssModules({
      generateSourceTypes: true,
    }),
    svgJar({ target: "ember" }),
    ember(),
    babel({
      babelHelpers: "runtime",
      extensions,
    }),
    command === "build" &&
      emberSsg({
        routes: ["index"],
        rehydrate: true,
      }),
    removeCrossOrigin(),
  ],
}));
