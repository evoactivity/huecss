import { describe, test, expect, vi } from "vitest";
import { setupRenderingContext } from "ember-vitest";
import { click } from "@ember/test-helpers";
import CssOutput from "#components/css-output/css-output";
import { generateTokens, activateColour } from "#utils/token-generator";

const SAMPLE_TOKENS = generateTokens([
  activateColour({ name: "red", lightness: 0.577, hue: 27.325, chroma: 0.2 }),
]);

describe("CssOutput", () => {
  test("renders the CSS output toggle label", async () => {
    await using ctx = await setupRenderingContext();

    await ctx.render(
      // @ts-expect-error -- TemplateOnlyComponent type mismatch in ember-vitest ctx.render
      <template><CssOutput @tokens={{SAMPLE_TOKENS}} /></template>,
    );

    expect(ctx.element.textContent?.toLowerCase()).toContain("css output");
  });

  test("code block is visible by default (isOpen = true)", async () => {
    await using ctx = await setupRenderingContext();

    await ctx.render(
      // @ts-expect-error -- TemplateOnlyComponent type mismatch in ember-vitest ctx.render
      <template><CssOutput @tokens={{SAMPLE_TOKENS}} /></template>,
    );

    const codeBlock = ctx.element.querySelector("[class*='codeBlock']");
    expect(codeBlock).toBeTruthy();
  });

  test("clicking toggle hides the code block", async () => {
    await using ctx = await setupRenderingContext();

    await ctx.render(
      // @ts-expect-error -- TemplateOnlyComponent type mismatch in ember-vitest ctx.render
      <template><CssOutput @tokens={{SAMPLE_TOKENS}} /></template>,
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
      <template><CssOutput @tokens={{SAMPLE_TOKENS}} /></template>,
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
      <template><CssOutput @tokens={{SAMPLE_TOKENS}} /></template>,
    );

    const copyButton = Array.from(ctx.element.querySelectorAll("button")).find((b) =>
      b.textContent?.includes("Copy"),
    );
    expect(copyButton).toBeTruthy();
  });

  test("copy button label changes to Copied! after click", async () => {
    await using ctx = await setupRenderingContext();
    vi.spyOn(navigator.clipboard, "writeText").mockResolvedValue(undefined);

    await ctx.render(
      // @ts-expect-error -- TemplateOnlyComponent type mismatch in ember-vitest ctx.render
      <template><CssOutput @tokens={{SAMPLE_TOKENS}} /></template>,
    );

    const copyButton = Array.from(ctx.element.querySelectorAll("button")).find((b) =>
      b.textContent?.includes("Copy"),
    ) as HTMLElement;
    await click(copyButton);

    expect(copyButton.textContent?.trim()).toBe("Copied!");
  });

  test("renders output mode tabs: oklch, rgb, hsl, hex", async () => {
    await using ctx = await setupRenderingContext();

    await ctx.render(
      // @ts-expect-error -- TemplateOnlyComponent type mismatch in ember-vitest ctx.render
      <template><CssOutput @tokens={{SAMPLE_TOKENS}} /></template>,
    );

    const text = ctx.element.textContent ?? "";
    expect(text).toContain("oklch");
    expect(text).toContain("rgb");
    expect(text).toContain("hsl");
    expect(text).toContain("hex");
  });

  test("oklch tab is active by default", async () => {
    await using ctx = await setupRenderingContext();

    await ctx.render(
      // @ts-expect-error -- TemplateOnlyComponent type mismatch in ember-vitest ctx.render
      <template><CssOutput @tokens={{SAMPLE_TOKENS}} /></template>,
    );

    const activeTab = ctx.element.querySelector("[role='tab'][aria-selected]");
    expect(activeTab?.textContent?.trim()).toBe("oklch");
  });

  test("clicking rgb tab changes output to rgb format", async () => {
    await using ctx = await setupRenderingContext();

    await ctx.render(
      // @ts-expect-error -- TemplateOnlyComponent type mismatch in ember-vitest ctx.render
      <template><CssOutput @tokens={{SAMPLE_TOKENS}} /></template>,
    );

    const rgbTab = Array.from(ctx.element.querySelectorAll("[role='tab']")).find(
      (b) => b.textContent?.trim() === "rgb",
    ) as HTMLElement;
    await click(rgbTab);

    const pre = ctx.element.querySelector("pre");
    expect(pre?.textContent).toContain("rgb(");
  });

  test("clicking hex tab changes output to hex format", async () => {
    await using ctx = await setupRenderingContext();

    await ctx.render(
      // @ts-expect-error -- TemplateOnlyComponent type mismatch in ember-vitest ctx.render
      <template><CssOutput @tokens={{SAMPLE_TOKENS}} /></template>,
    );

    const hexTab = Array.from(ctx.element.querySelectorAll("[role='tab']")).find(
      (b) => b.textContent?.trim() === "hex",
    ) as HTMLElement;
    await click(hexTab);

    const pre = ctx.element.querySelector("pre");
    expect(pre?.textContent).toMatch(/#[0-9a-f]{6}/i);
  });
});
