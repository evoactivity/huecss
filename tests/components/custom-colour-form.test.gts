import { describe, test, expect, vi } from "vitest";
import { setupRenderingContext } from "ember-vitest";
import { fillIn, click } from "@ember/test-helpers";
import { array } from "@ember/helper";
import CustomColourForm from "#components/custom-colour-form/custom-colour-form";

describe("CustomColourForm", () => {
  test("renders name input and add button", async () => {
    await using ctx = await setupRenderingContext();
    const onAdd = vi.fn();

    await ctx.render(
      // @ts-expect-error -- TemplateOnlyComponent type mismatch in ember-vitest ctx.render
      <template><CustomColourForm @existingNames={{(array)}} @onAdd={{onAdd}} /></template>,
    );

    expect(ctx.element.querySelector("#custom-colour-name")).toBeTruthy();
    expect(ctx.element.querySelector("button[type='submit']")).toBeTruthy();
  });

  test("submit button is disabled when name is empty", async () => {
    await using ctx = await setupRenderingContext();
    const onAdd = vi.fn();

    await ctx.render(
      // @ts-expect-error -- TemplateOnlyComponent type mismatch in ember-vitest ctx.render
      <template><CustomColourForm @existingNames={{(array)}} @onAdd={{onAdd}} /></template>,
    );

    const button = ctx.element.querySelector("button[type='submit']") as HTMLButtonElement;
    expect(button.disabled).toBe(true);
  });

  test("shows error when name already exists", async () => {
    await using ctx = await setupRenderingContext();
    const onAdd = vi.fn();
    const existingNames = ["brand"];

    await ctx.render(
      // @ts-expect-error -- TemplateOnlyComponent type mismatch in ember-vitest ctx.render
      <template><CustomColourForm @existingNames={{existingNames}} @onAdd={{onAdd}} /></template>,
    );

    await fillIn("#custom-colour-name", "brand");
    expect(ctx.element.textContent).toContain("already exists");
  });

  test("calls onAdd with name, hue, lightness and chroma on valid submit", async () => {
    await using ctx = await setupRenderingContext();
    const onAdd = vi.fn();

    await ctx.render(
      // @ts-expect-error -- TemplateOnlyComponent type mismatch in ember-vitest ctx.render
      <template><CustomColourForm @existingNames={{(array)}} @onAdd={{onAdd}} /></template>,
    );

    await fillIn("#custom-colour-name", "brand");
    await click("button[type='submit']");

    expect(onAdd).toHaveBeenCalledOnce();
    const call = onAdd.mock.calls[0] as [
      { name: string; hue: number; lightness: number; chroma: number },
    ];
    expect(call[0]).toMatchObject({ name: "brand" });
    expect(typeof call[0].hue).toBe("number");
    expect(typeof call[0].lightness).toBe("number");
    expect(typeof call[0].chroma).toBe("number");
  });
});
