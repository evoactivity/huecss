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
});
