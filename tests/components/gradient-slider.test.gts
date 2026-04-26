import { describe, test, expect, vi } from "vitest";
import { setupRenderingContext } from "ember-vitest";
import GradientSlider from "#components/gradient-slider/gradient-slider";

const GRADIENT = "linear-gradient(to right, oklch(0 0 0), oklch(1 0 0))";
const THUMB = "oklch(0.5 0 0)";

describe("GradientSlider", () => {
  test("renders the label text", async () => {
    await using ctx = await setupRenderingContext();
    const onChange = vi.fn();

    await ctx.render(
      <template>
        <GradientSlider
          @label="Lightness"
          @min={{0}}
          @max={{1}}
          @step={{0.001}}
          @value={{0.5}}
          @gradient={{GRADIENT}}
          @thumbColour={{THUMB}}
          @displayValue="50.0%"
          @onChange={{onChange}}
        />
      </template>,
    );

    expect(ctx.element.textContent).toContain("Lightness");
  });

  test("renders the display value", async () => {
    await using ctx = await setupRenderingContext();
    const onChange = vi.fn();

    await ctx.render(
      <template>
        <GradientSlider
          @label="Lightness"
          @min={{0}}
          @max={{1}}
          @step={{0.001}}
          @value={{0.5}}
          @gradient={{GRADIENT}}
          @thumbColour={{THUMB}}
          @displayValue="50.0%"
          @onChange={{onChange}}
        />
      </template>,
    );

    expect(ctx.element.textContent).toContain("50.0%");
  });

  test("renders a range input with correct min/max/step", async () => {
    await using ctx = await setupRenderingContext();
    const onChange = vi.fn();

    await ctx.render(
      <template>
        <GradientSlider
          @label="Lightness"
          @min={{0}}
          @max={{1}}
          @step={{0.001}}
          @value={{0.5}}
          @gradient={{GRADIENT}}
          @thumbColour={{THUMB}}
          @displayValue="50.0%"
          @onChange={{onChange}}
        />
      </template>,
    );

    const input = ctx.element.querySelector("input[type='range']") as HTMLInputElement;
    expect(input).toBeTruthy();
    expect(input.min).toBe("0");
    expect(input.max).toBe("1");
    expect(input.step).toBe("0.001");
  });

  test("calls onChange with parsed float when input fires", async () => {
    await using ctx = await setupRenderingContext();
    const onChange = vi.fn();

    await ctx.render(
      <template>
        <GradientSlider
          @label="Lightness"
          @min={{0}}
          @max={{1}}
          @step={{0.001}}
          @value={{0.5}}
          @gradient={{GRADIENT}}
          @thumbColour={{THUMB}}
          @displayValue="50.0%"
          @onChange={{onChange}}
        />
      </template>,
    );

    const input = ctx.element.querySelector("input[type='range']") as HTMLInputElement;
    input.value = "0.75";
    input.dispatchEvent(new Event("input", { bubbles: true }));

    expect(onChange).toHaveBeenCalledWith(0.75);
  });
});
