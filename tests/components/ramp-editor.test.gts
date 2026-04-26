import { describe, test, expect } from "vitest";
import { setupRenderingContext } from "ember-vitest";
import { click } from "@ember/test-helpers";
import RampEditor from "#components/ramp-editor/ramp-editor";
import { activateColour } from "#utils/token-generator";
import { generateTokens } from "#utils/token-generator";
import { TONES } from "#utils/colours";

const blue = activateColour({ name: "blue", lightness: 0.546, chroma: 0.232, hue: 264 });

describe("RampEditor", () => {
  test("renders a swatch button for each tone", async () => {
    await using ctx = await setupRenderingContext();
    const tokens = generateTokens([blue]);

    await ctx.render(
      // @ts-expect-error -- TemplateOnlyComponent type mismatch in ember-vitest ctx.render
      <template><RampEditor @active={{blue}} @tokens={{tokens}} /></template>,
    );

    const swatches = ctx.element.querySelectorAll("button[title^='Tone']");
    expect(swatches.length).toBe(TONES.length);
  });

  test("clicking a swatch opens the modal", async () => {
    await using ctx = await setupRenderingContext();
    const tokens = generateTokens([blue]);

    await ctx.render(
      // @ts-expect-error -- TemplateOnlyComponent type mismatch in ember-vitest ctx.render
      <template><RampEditor @active={{blue}} @tokens={{tokens}} /></template>,
    );

    await click("button[title='Tone 500 (seeded)']");

    // Modal should be visible -- it contains tone picker inputs
    expect(ctx.element.querySelector("input[type='text']")).toBeTruthy();
  });

  test("clicking the same swatch again closes the modal", async () => {
    await using ctx = await setupRenderingContext();
    const tokens = generateTokens([blue]);

    await ctx.render(
      // @ts-expect-error -- TemplateOnlyComponent type mismatch in ember-vitest ctx.render
      <template><RampEditor @active={{blue}} @tokens={{tokens}} /></template>,
    );

    await click("button[title='Tone 500 (seeded)']");
    await click("button[title='Tone 500 (seeded)']");

    expect(ctx.element.querySelector("input[type='text']")).toBeFalsy();
  });

  test("switching to a different tone updates the modal title", async () => {
    await using ctx = await setupRenderingContext();
    const tokens = generateTokens([blue]);

    await ctx.render(
      // @ts-expect-error -- TemplateOnlyComponent type mismatch in ember-vitest ctx.render
      <template><RampEditor @active={{blue}} @tokens={{tokens}} /></template>,
    );

    await click("button[title='Tone 500 (seeded)']");
    expect(ctx.element.textContent).toContain("Tone 500");

    // Click a different tone -- modal should update in place
    await click("button[title='Tone 50 (seeded)']");
    expect(ctx.element.textContent).toContain("Tone 50");
  });

  test("onPickerChange adds a new anchor when tone has no anchor", async () => {
    await using ctx = await setupRenderingContext();
    const tokens = generateTokens([blue]);

    await ctx.render(
      // @ts-expect-error -- TemplateOnlyComponent type mismatch in ember-vitest ctx.render
      <template><RampEditor @active={{blue}} @tokens={{tokens}} /></template>,
    );

    const initialAnchorCount = blue.anchors.length;

    // Open tone 200 (no anchor by default)
    await click("button[title='Tone 200']");

    // Simulate a colour change via the text input
    const input = ctx.element.querySelector("input[type='text']") as HTMLInputElement;
    input.focus();
    input.dispatchEvent(new Event("focus", { bubbles: true }));
    input.value = "#ff0000";
    input.dispatchEvent(new Event("input", { bubbles: true }));

    expect(blue.anchors.length).toBeGreaterThan(initialAnchorCount);
  });
});
