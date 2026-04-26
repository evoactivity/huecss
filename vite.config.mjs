import { defineConfig } from "vite";
import { extensions, ember } from "@embroider/vite";
import { babel } from "@rollup/plugin-babel";
import { preview } from "@vitest/browser-preview";
import { playwright } from "@vitest/browser-playwright";

const isCI = process.env.CI === "true";

function removeCrossOrigin() {
  return {
    name: "remove-crossorigin",
    transformIndexHtml(html) {
      return html.replace(/ crossorigin /g, " ");
    },
  };
}

export default defineConfig({
  base: "/huecss/",
  test: {
    include: ["tests/**/*.test.{gjs,gts,ts}"],
    maxConcurrency: 1,
    browser: {
      provider: isCI ? playwright() : preview(),
      enabled: true,
      headless: isCI,
      instances: [{ browser: "chromium" }],
    },
  },
  plugins: [
    ember(),
    babel({
      babelHelpers: "runtime",
      extensions,
    }),
    removeCrossOrigin(),
  ],
});
