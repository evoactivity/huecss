import { describe, test, expect } from "vitest";
import { setupRenderingContext } from "ember-vitest";
import App from "#app/app";
import AppHeader from "#components/app-header/app-header";

describe("AppHeader", () => {
  test("renders the wordmark", async () => {
    await using ctx = await setupRenderingContext(App);
    await ctx.render(<template><AppHeader /></template>);

    expect(ctx.element.textContent).toContain("huecss");
  });

  test("does not render an interpolation mode selector", async () => {
    await using ctx = await setupRenderingContext(App);
    await ctx.render(<template><AppHeader /></template>);

    expect(ctx.element.querySelectorAll("[role='tab']").length).toBe(0);
  });

  test("links to the source repo on GitHub", async () => {
    await using ctx = await setupRenderingContext(App);
    await ctx.render(<template><AppHeader /></template>);

    const link = ctx.element.querySelector("a[href*='github.com']");
    expect(link).toBeTruthy();
    expect(link?.getAttribute("href")).toBe("https://github.com/evoactivity/huecss");
    expect(link?.getAttribute("target")).toBe("_blank");
    expect(link?.getAttribute("rel")).toContain("noopener");
    expect(link?.getAttribute("aria-label")).toMatch(/github/i);
    // The svg-jar plugin renders the icon as an SVG element nested inside.
    expect(link?.querySelector("svg")).toBeTruthy();
  });
});
