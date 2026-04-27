import { describe, test, expect } from "vitest";
import { setupRenderingContext } from "ember-vitest";
import { click } from "@ember/test-helpers";
import App from "#app/app";
import AppHeader from "#components/app-header/app-header";
import type ColourStudio from "#services/colour-studio";

describe("AppHeader", () => {
  test("renders the wordmark", async () => {
    await using ctx = await setupRenderingContext(App);
    await ctx.render(
      // @ts-expect-error -- TemplateOnlyComponent type mismatch in ember-vitest ctx.render
      <template><AppHeader /></template>,
    );

    expect(ctx.element.textContent).toContain("huecss");
  });

  test("renders a tab for each interpolation mode", async () => {
    await using ctx = await setupRenderingContext(App);
    await ctx.render(
      // @ts-expect-error -- TemplateOnlyComponent type mismatch in ember-vitest ctx.render
      <template><AppHeader /></template>,
    );

    const tabs = ctx.element.querySelectorAll("[role='tab']");
    expect(tabs.length).toBe(4);
    const labels = Array.from(tabs).map((t) => t.textContent?.trim());
    expect(labels).toContain("oklch");
    expect(labels).toContain("oklab");
    expect(labels).toContain("lch");
    expect(labels).toContain("lab");
  });

  test("marks the active tab with the active class based on service state", async () => {
    await using ctx = await setupRenderingContext(App);
    const studio = ctx.owner.lookup("service:colour-studio") as ColourStudio;
    studio.setInterpolationMode("oklab");

    await ctx.render(
      // @ts-expect-error -- TemplateOnlyComponent type mismatch in ember-vitest ctx.render
      <template><AppHeader /></template>,
    );

    const active = ctx.element.querySelector("[role='tab'][aria-selected]");
    expect(active?.textContent?.trim()).toBe("oklab");
  });

  test("clicking a tab updates the service interpolationMode", async () => {
    await using ctx = await setupRenderingContext(App);
    const studio = ctx.owner.lookup("service:colour-studio") as ColourStudio;

    await ctx.render(
      // @ts-expect-error -- TemplateOnlyComponent type mismatch in ember-vitest ctx.render
      <template><AppHeader /></template>,
    );

    const tabs = ctx.element.querySelectorAll("[role='tab']");
    const lchTab = Array.from(tabs).find((t) => t.textContent?.trim() === "lch") as HTMLElement;
    await click(lchTab);

    expect(studio.interpolationMode).toBe("lch");
  });
});
