import { describe, test, expect, vi } from "vitest";
import { setupRenderingContext } from "ember-vitest";
import { click } from "@ember/test-helpers";
import AppHeader from "#components/app-header/app-header";

describe("AppHeader", () => {
  test("renders the wordmark", async () => {
    await using ctx = await setupRenderingContext();
    const onModeChange = vi.fn();

    await ctx.render(
      <template><AppHeader @interpolationMode="oklch" @onModeChange={{onModeChange}} /></template>,
    );

    expect(ctx.element.textContent).toContain("huecss");
  });

  test("renders a tab for each interpolation mode", async () => {
    await using ctx = await setupRenderingContext();
    const onModeChange = vi.fn();

    await ctx.render(
      <template><AppHeader @interpolationMode="oklch" @onModeChange={{onModeChange}} /></template>,
    );

    const tabs = ctx.element.querySelectorAll("[role='tab']");
    expect(tabs.length).toBe(4);
    const labels = Array.from(tabs).map((t) => t.textContent?.trim());
    expect(labels).toContain("oklch");
    expect(labels).toContain("oklab");
    expect(labels).toContain("lch");
    expect(labels).toContain("lab");
  });

  test("marks the active tab with the active class", async () => {
    await using ctx = await setupRenderingContext();
    const onModeChange = vi.fn();

    await ctx.render(
      <template><AppHeader @interpolationMode="oklab" @onModeChange={{onModeChange}} /></template>,
    );

    const active = ctx.element.querySelector(".app-header__tab--active");
    expect(active?.textContent?.trim()).toBe("oklab");
  });

  test("calls onModeChange with the clicked mode", async () => {
    await using ctx = await setupRenderingContext();
    const onModeChange = vi.fn();

    await ctx.render(
      <template><AppHeader @interpolationMode="oklch" @onModeChange={{onModeChange}} /></template>,
    );

    const tabs = ctx.element.querySelectorAll("[role='tab']");
    const lchTab = Array.from(tabs).find((t) => t.textContent?.trim() === "lch") as HTMLElement;
    await click(lchTab);

    expect(onModeChange).toHaveBeenCalledWith("lch");
  });
});
