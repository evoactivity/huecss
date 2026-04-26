import { describe, test, expect, vi } from "vitest";
import { setupRenderingContext } from "ember-vitest";
import { click } from "@ember/test-helpers";
import DraggableModal from "#components/draggable-modal/draggable-modal";

const POSITION = { x: 100, y: 100 };

describe("DraggableModal", () => {
  test("renders yielded content", async () => {
    await using ctx = await setupRenderingContext();
    const onClose = vi.fn();

    await ctx.render(
      // @ts-expect-error -- TemplateOnlyComponent type mismatch in ember-vitest ctx.render
      <template>
        <DraggableModal @title="Test" @position={{POSITION}} @onClose={{onClose}}>
          <span id="inner">hello</span>
        </DraggableModal>
      </template>,
    );

    expect(ctx.element.querySelector("#inner")?.textContent).toBe("hello");
  });

  test("renders the title", async () => {
    await using ctx = await setupRenderingContext();
    const onClose = vi.fn();

    await ctx.render(
      // @ts-expect-error -- TemplateOnlyComponent type mismatch in ember-vitest ctx.render
      <template>
        <DraggableModal @title="Tone 500" @position={{POSITION}} @onClose={{onClose}}>
          content
        </DraggableModal>
      </template>,
    );

    expect(ctx.element.textContent).toContain("Tone 500");
  });

  test("close button calls onClose", async () => {
    await using ctx = await setupRenderingContext();
    const onClose = vi.fn();

    await ctx.render(
      // @ts-expect-error -- TemplateOnlyComponent type mismatch in ember-vitest ctx.render
      <template>
        <DraggableModal @title="Test" @position={{POSITION}} @onClose={{onClose}}>
          content
        </DraggableModal>
      </template>,
    );

    await click("button[aria-label='Close']");

    expect(onClose).toHaveBeenCalledOnce();
  });

  test("Escape key calls onClose", async () => {
    await using ctx = await setupRenderingContext();
    const onClose = vi.fn();

    await ctx.render(
      // @ts-expect-error -- TemplateOnlyComponent type mismatch in ember-vitest ctx.render
      <template>
        <DraggableModal @title="Test" @position={{POSITION}} @onClose={{onClose}}>
          content
        </DraggableModal>
      </template>,
    );

    document.dispatchEvent(new KeyboardEvent("keydown", { key: "Escape", bubbles: true }));

    expect(onClose).toHaveBeenCalledOnce();
  });

  test("pointerdown inside the modal does not call onClose", async () => {
    await using ctx = await setupRenderingContext();
    const onClose = vi.fn();

    await ctx.render(
      // @ts-expect-error -- TemplateOnlyComponent type mismatch in ember-vitest ctx.render
      <template>
        <DraggableModal @title="Test" @position={{POSITION}} @onClose={{onClose}}>
          <span id="inner">content</span>
        </DraggableModal>
      </template>,
    );

    // Wait for the deferred setTimeout(0) that arms the outside listener
    await new Promise((r) => setTimeout(r, 10));

    // Fire pointerdown on the inner element -- should not close
    const inner = ctx.element.querySelector("#inner") as HTMLElement;
    inner.dispatchEvent(new PointerEvent("pointerdown", { bubbles: true }));

    expect(onClose).not.toHaveBeenCalled();
  });

  test("click outside the modal calls onClose", async () => {
    await using ctx = await setupRenderingContext();
    const onClose = vi.fn();

    await ctx.render(
      // @ts-expect-error -- TemplateOnlyComponent type mismatch in ember-vitest ctx.render
      <template>
        <DraggableModal @title="Test" @position={{POSITION}} @onClose={{onClose}}>
          content
        </DraggableModal>
      </template>,
    );

    // ember-click-outside defers listener registration by one tick
    await new Promise((r) => setTimeout(r, 10));

    document.dispatchEvent(new MouseEvent("click", { bubbles: true }));

    expect(onClose).toHaveBeenCalledOnce();
  });

  test("click inside the modal does not call onClose", async () => {
    await using ctx = await setupRenderingContext();
    const onClose = vi.fn();

    await ctx.render(
      // @ts-expect-error -- TemplateOnlyComponent type mismatch in ember-vitest ctx.render
      <template>
        <DraggableModal @title="Test" @position={{POSITION}} @onClose={{onClose}}>
          <span id="inner">content</span>
        </DraggableModal>
      </template>,
    );

    await new Promise((r) => setTimeout(r, 10));

    const inner = ctx.element.querySelector("#inner") as HTMLElement;
    inner.dispatchEvent(new MouseEvent("click", { bubbles: true }));

    expect(onClose).not.toHaveBeenCalled();
  });

  test("applies position as inline style", async () => {
    await using ctx = await setupRenderingContext();
    const onClose = vi.fn();
    const position = { x: 42, y: 99 };

    await ctx.render(
      // @ts-expect-error -- TemplateOnlyComponent type mismatch in ember-vitest ctx.render
      <template>
        <DraggableModal @title="Test" @position={{position}} @onClose={{onClose}}>
          content
        </DraggableModal>
      </template>,
    );

    const modal = ctx.element.querySelector("[style]") as HTMLElement;
    expect(modal?.style.left).toBe("42px");
    expect(modal?.style.top).toBe("99px");
  });
});
