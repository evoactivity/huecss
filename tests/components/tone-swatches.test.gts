import { describe, test, expect } from "vitest";
import { setupRenderingContext } from "ember-vitest";
import ToneSwatches from "#components/tone-swatches/tone-swatches";
import type { ColourToken } from "#utils/token-generator";
import { TONES } from "#utils/colours";
import type { Tone } from "#utils/colours";

function makeTokens(name: string): ColourToken[] {
  return TONES.map((tone: Tone, i: number) => ({
    name,
    tone,
    variable: `--color-${name}-${tone}`,
    value: `${(0.9 - i * 0.07).toFixed(4)} 0.1 264`,
    l: 0.9 - i * 0.07,
    c: 0.1,
    h: 264,
  }));
}

describe("ToneSwatches", () => {
  test("renders a swatch for each token", async () => {
    await using ctx = await setupRenderingContext();
    const tokens = makeTokens("blue");

    await ctx.render(<template><ToneSwatches @tokens={{tokens}} /></template>);

    const swatches = ctx.element.querySelectorAll("[title^='--color-blue-']");
    expect(swatches.length).toBe(TONES.length);
  });

  test("renders the colour name label", async () => {
    await using ctx = await setupRenderingContext();
    const tokens = makeTokens("emerald");

    await ctx.render(<template><ToneSwatches @tokens={{tokens}} /></template>);

    expect(ctx.element.textContent).toContain("emerald");
  });

  test("renders multiple colour groups", async () => {
    await using ctx = await setupRenderingContext();
    const tokens: ColourToken[] = [...makeTokens("blue"), ...makeTokens("red")];

    await ctx.render(<template><ToneSwatches @tokens={{tokens}} /></template>);

    expect(ctx.element.textContent).toContain("blue");
    expect(ctx.element.textContent).toContain("red");
  });

  test("renders nothing when tokens array is empty", async () => {
    await using ctx = await setupRenderingContext();
    const tokens: ColourToken[] = [];

    await ctx.render(<template><ToneSwatches @tokens={{tokens}} /></template>);

    expect(ctx.element.textContent?.trim()).toBe("");
  });
});
