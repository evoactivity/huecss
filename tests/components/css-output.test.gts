import { describe, test, expect, vi } from "vitest";
import { setupRenderingContext } from "ember-vitest";
import { click } from "@ember/test-helpers";
import CssOutput from "#components/css-output/css-output";

const SAMPLE_CSS = ":root {\n  /* red */\n  --color-red-50: oklch(95% 0.01 25);\n}\n";

describe("CssOutput", () => {
  test("renders the CSS output toggle label", async () => {
    await using ctx = await setupRenderingContext();

    await ctx.render(
      // @ts-expect-error -- TemplateOnlyComponent type mismatch in ember-vitest ctx.render
      <template><CssOutput @css={{SAMPLE_CSS}} /></template>,
    );

    expect(ctx.element.textContent?.toLowerCase()).toContain("css output");
  });

  test("code block is visible by default (isOpen = true)", async () => {
    await using ctx = await setupRenderingContext();

    await ctx.render(
      // @ts-expect-error -- TemplateOnlyComponent type mismatch in ember-vitest ctx.render
      <template><CssOutput @css={{SAMPLE_CSS}} /></template>,
    );

    const codeBlock = ctx.element.querySelector("[class*='codeBlock']");
    expect(codeBlock).toBeTruthy();
  });

  test("clicking toggle hides the code block", async () => {
    await using ctx = await setupRenderingContext();

    await ctx.render(
      // @ts-expect-error -- TemplateOnlyComponent type mismatch in ember-vitest ctx.render
      <template><CssOutput @css={{SAMPLE_CSS}} /></template>,
    );

    const toggle = ctx.element.querySelector("[class*='toggle']") as HTMLElement;
    await click(toggle);

    const codeBlock = ctx.element.querySelector("[class*='codeBlock']");
    expect(codeBlock).toBeFalsy();
  });

  test("clicking toggle twice restores the code block", async () => {
    await using ctx = await setupRenderingContext();

    await ctx.render(
      // @ts-expect-error -- TemplateOnlyComponent type mismatch in ember-vitest ctx.render
      <template><CssOutput @css={{SAMPLE_CSS}} /></template>,
    );

    const toggle = ctx.element.querySelector("[class*='toggle']") as HTMLElement;
    await click(toggle);
    await click(toggle);

    const codeBlock = ctx.element.querySelector("[class*='codeBlock']");
    expect(codeBlock).toBeTruthy();
  });

  test("renders a copy button", async () => {
    await using ctx = await setupRenderingContext();

    await ctx.render(
      // @ts-expect-error -- TemplateOnlyComponent type mismatch in ember-vitest ctx.render
      <template><CssOutput @css={{SAMPLE_CSS}} /></template>,
    );

    const copyButton = Array.from(ctx.element.querySelectorAll("button")).find((b) =>
      b.textContent?.includes("Copy"),
    );
    expect(copyButton).toBeTruthy();
  });

  test("copy button label changes to Copied! after click", async () => {
    await using ctx = await setupRenderingContext();
    // Mock clipboard API -- navigator.clipboard is read-only so use defineProperty
    vi.spyOn(navigator.clipboard, "writeText").mockResolvedValue(undefined);

    await ctx.render(
      // @ts-expect-error -- TemplateOnlyComponent type mismatch in ember-vitest ctx.render
      <template><CssOutput @css={{SAMPLE_CSS}} /></template>,
    );

    const copyButton = Array.from(ctx.element.querySelectorAll("button")).find((b) =>
      b.textContent?.includes("Copy"),
    ) as HTMLElement;
    await click(copyButton);

    expect(copyButton.textContent?.trim()).toBe("Copied!");
  });
});
