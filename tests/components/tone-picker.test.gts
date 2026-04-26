import { describe, test, expect, vi } from "vitest";
import { setupRenderingContext } from "ember-vitest";
import { fillIn } from "@ember/test-helpers";
import TonePicker from "#components/ramp-editor/tone-picker";
import type { ToneAnchor } from "#utils/interpolate";
import type { ColourToken } from "#utils/token-generator";

const anchor: ToneAnchor = { tone: 500, l: 0.6, c: 0.2, h: 264, seeded: false };
const token: ColourToken = {
  name: "blue",
  tone: 500,
  variable: "--color-blue-500",
  value: "60% 0.2 264",
  l: 0.6,
  c: 0.2,
  h: 264,
};

describe("TonePicker", () => {
  test("renders hue wheel and sliders", async () => {
    await using ctx = await setupRenderingContext();
    const onChange = vi.fn();
    const onRemove = vi.fn();
    const onClose = vi.fn();

    await ctx.render(
      // @ts-expect-error -- TemplateOnlyComponent type mismatch in ember-vitest ctx.render
      <template>
        <TonePicker
          @tone={{500}}
          @anchor={{anchor}}
          @token={{token}}
          @isEndpoint={{true}}
          @onChange={{onChange}}
          @onRemove={{onRemove}}
          @onClose={{onClose}}
        />
      </template>,
    );

    expect(ctx.element.querySelector("svg")).toBeTruthy();
    expect(ctx.element.querySelectorAll("input[type='range']").length).toBe(2);
  });

  test("colour input reflects current colour as oklch string when unfocused", async () => {
    await using ctx = await setupRenderingContext();
    const onChange = vi.fn();
    const onRemove = vi.fn();
    const onClose = vi.fn();

    await ctx.render(
      // @ts-expect-error -- TemplateOnlyComponent type mismatch in ember-vitest ctx.render
      <template>
        <TonePicker
          @tone={{500}}
          @anchor={{anchor}}
          @token={{token}}
          @isEndpoint={{false}}
          @onChange={{onChange}}
          @onRemove={{onRemove}}
          @onClose={{onClose}}
        />
      </template>,
    );

    const input = ctx.element.querySelector("input[type='text']") as HTMLInputElement;
    expect(input.value).toMatch(/^oklch\(/);
    expect(input.value).toContain("%");
  });

  test("typing a valid hex colour calls onChange", async () => {
    await using ctx = await setupRenderingContext();
    const onChange = vi.fn();
    const onRemove = vi.fn();
    const onClose = vi.fn();

    await ctx.render(
      // @ts-expect-error -- TemplateOnlyComponent type mismatch in ember-vitest ctx.render
      <template>
        <TonePicker
          @tone={{500}}
          @anchor={{anchor}}
          @token={{token}}
          @isEndpoint={{false}}
          @onChange={{onChange}}
          @onRemove={{onRemove}}
          @onClose={{onClose}}
        />
      </template>,
    );

    const input = ctx.element.querySelector("input[type='text']") as HTMLInputElement;
    input.focus();
    input.dispatchEvent(new Event("focus", { bubbles: true }));
    await fillIn(input, "#ff0000");

    expect(onChange).toHaveBeenCalledOnce();
    const args = onChange.mock.calls[0]![0] as { l: number; c: number; h: number };
    expect(typeof args.l).toBe("number");
    expect(typeof args.c).toBe("number");
    expect(typeof args.h).toBe("number");
  });

  test("shows remove button for non-endpoint user anchor", async () => {
    await using ctx = await setupRenderingContext();
    const onChange = vi.fn();
    const onRemove = vi.fn();
    const onClose = vi.fn();

    await ctx.render(
      // @ts-expect-error -- TemplateOnlyComponent type mismatch in ember-vitest ctx.render
      <template>
        <TonePicker
          @tone={{200}}
          @anchor={{anchor}}
          @token={{token}}
          @isEndpoint={{false}}
          @onChange={{onChange}}
          @onRemove={{onRemove}}
          @onClose={{onClose}}
        />
      </template>,
    );

    expect(ctx.element.textContent).toContain("Remove anchor");
  });

  test("shows reset button for endpoint", async () => {
    await using ctx = await setupRenderingContext();
    const onChange = vi.fn();
    const onRemove = vi.fn();
    const onClose = vi.fn();

    await ctx.render(
      // @ts-expect-error -- TemplateOnlyComponent type mismatch in ember-vitest ctx.render
      <template>
        <TonePicker
          @tone={{500}}
          @anchor={{anchor}}
          @token={{token}}
          @isEndpoint={{true}}
          @onChange={{onChange}}
          @onRemove={{onRemove}}
          @onClose={{onClose}}
        />
      </template>,
    );

    expect(ctx.element.textContent).toContain("Reset to default");
  });

  test("no remove/reset button when no anchor and not endpoint", async () => {
    await using ctx = await setupRenderingContext();
    const onChange = vi.fn();
    const onRemove = vi.fn();
    const onClose = vi.fn();

    await ctx.render(
      // @ts-expect-error -- TemplateOnlyComponent type mismatch in ember-vitest ctx.render
      <template>
        <TonePicker
          @tone={{200}}
          @anchor={{undefined}}
          @token={{token}}
          @isEndpoint={{false}}
          @onChange={{onChange}}
          @onRemove={{onRemove}}
          @onClose={{onClose}}
        />
      </template>,
    );

    expect(ctx.element.textContent).not.toContain("Remove anchor");
    expect(ctx.element.textContent).not.toContain("Reset to default");
  });
});
