import { describe, test, expect } from "vitest";
import { setupRenderingContext } from "ember-vitest";
import { click } from "@ember/test-helpers";
import App from "#app/app";
import RampEditor from "#components/ramp-editor/ramp-editor";
import { activateColour, generateTokens } from "#utils/token-generator";
import { TONES } from "#utils/colours";

const blue = activateColour({ name: "blue", lightness: 0.546, chroma: 0.232, hue: 264 });

describe("RampEditor", () => {
  test("renders a swatch button for each tone", async () => {
    await using ctx = await setupRenderingContext(App);
    const tokens = generateTokens([blue]);

    await ctx.render(<template><RampEditor @active={{blue}} @tokens={{tokens}} /></template>);

    const swatches = ctx.element.querySelectorAll("button[title^='Tone']");
    expect(swatches.length).toBe(TONES.length);
  });

  test("clicking a swatch opens the modal", async () => {
    await using ctx = await setupRenderingContext(App);
    const tokens = generateTokens([blue]);

    await ctx.render(<template><RampEditor @active={{blue}} @tokens={{tokens}} /></template>);

    await click("button[title='Tone 500 (anchored)']");

    expect(ctx.element.querySelector("input[type='text']")).toBeTruthy();
  });

  test("clicking the same swatch again closes the modal", async () => {
    await using ctx = await setupRenderingContext(App);
    const tokens = generateTokens([blue]);

    await ctx.render(<template><RampEditor @active={{blue}} @tokens={{tokens}} /></template>);

    await click("button[title='Tone 500 (anchored)']");
    await click("button[title='Tone 500 (anchored)']");

    expect(ctx.element.querySelector("input[type='text']")).toBeFalsy();
  });

  test("switching to a different tone updates the modal title", async () => {
    await using ctx = await setupRenderingContext(App);
    const tokens = generateTokens([blue]);

    await ctx.render(<template><RampEditor @active={{blue}} @tokens={{tokens}} /></template>);

    await click("button[title='Tone 500 (anchored)']");
    expect(ctx.element.textContent).toContain("Tone 500");

    await click("button[title='Tone 50 (anchored)']");
    expect(ctx.element.textContent).toContain("Tone 50");
  });

  test("onPickerChange adds a new anchor when tone has no anchor", async () => {
    await using ctx = await setupRenderingContext(App);
    const active = activateColour({ name: "blue", lightness: 0.546, chroma: 0.232, hue: 264 });
    const tokens = generateTokens([active]);

    await ctx.render(<template><RampEditor @active={{active}} @tokens={{tokens}} /></template>);

    const initialAnchorCount = active.anchors.length;
    expect(initialAnchorCount).toBe(3);

    await click("button[title='Tone 200']");

    const input = ctx.element.querySelector("input[type='text']") as HTMLInputElement;
    input.focus();
    input.dispatchEvent(new Event("focus", { bubbles: true }));
    input.value = "#ff0000";
    input.dispatchEvent(new Event("input", { bubbles: true }));

    expect(active.anchors.length).toBe(4);
  });
});
