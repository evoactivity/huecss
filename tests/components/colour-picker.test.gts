import { describe, test, expect, vi } from "vitest";
import { setupRenderingContext } from "ember-vitest";
import { click } from "@ember/test-helpers";
import { array } from "@ember/helper";
import ColourPicker from "#components/colour-picker/colour-picker";
import type { ColourDefinition } from "#utils/colours";
import { activateColour } from "#utils/token-generator";

const red: ColourDefinition = { name: "red", lightness: 0.637, chroma: 0.237, hue: 25 };
const blue: ColourDefinition = { name: "blue", lightness: 0.546, chroma: 0.232, hue: 264 };
const colours = [red, blue];

describe("ColourPicker", () => {
  test("renders a button for each colour", async () => {
    await using ctx = await setupRenderingContext();
    const onToggle = vi.fn();

    await ctx.render(
      <template>
        <ColourPicker @colours={{colours}} @activeColours={{(array)}} @onToggle={{onToggle}} />
      </template>,
    );

    const buttons = ctx.element.querySelectorAll("button");
    expect(buttons.length).toBe(2);
  });

  test("renders colour names as title attributes", async () => {
    await using ctx = await setupRenderingContext();
    const onToggle = vi.fn();

    await ctx.render(
      <template>
        <ColourPicker @colours={{colours}} @activeColours={{(array)}} @onToggle={{onToggle}} />
      </template>,
    );

    const titles = Array.from(ctx.element.querySelectorAll("button")).map((b) =>
      b.getAttribute("title"),
    );
    expect(titles).toContain("red");
    expect(titles).toContain("blue");
  });

  test("calls onToggle with the colour when a swatch is clicked", async () => {
    await using ctx = await setupRenderingContext();
    const onToggle = vi.fn();

    await ctx.render(
      <template>
        <ColourPicker @colours={{colours}} @activeColours={{(array)}} @onToggle={{onToggle}} />
      </template>,
    );

    await click("button[title='red']");
    expect(onToggle).toHaveBeenCalledOnce();
    expect(onToggle.mock.calls[0]![0]).toMatchObject({ name: "red" });
  });

  test("active swatch has active class", async () => {
    await using ctx = await setupRenderingContext();
    const onToggle = vi.fn();
    const activeColours = [activateColour(red)];

    await ctx.render(
      <template>
        <ColourPicker
          @colours={{colours}}
          @activeColours={{activeColours}}
          @onToggle={{onToggle}}
        />
      </template>,
    );

    const redButton = ctx.element.querySelector("button[title='red']");
    const blueButton = ctx.element.querySelector("button[title='blue']");
    expect(redButton?.className).toContain("active");
    expect(blueButton?.className).not.toContain("active");
  });

  test("renders nothing when colours array is empty", async () => {
    await using ctx = await setupRenderingContext();
    const onToggle = vi.fn();
    const empty: ColourDefinition[] = [];

    await ctx.render(
      <template>
        <ColourPicker @colours={{empty}} @activeColours={{(array)}} @onToggle={{onToggle}} />
      </template>,
    );

    expect(ctx.element.querySelectorAll("button").length).toBe(0);
  });
});
