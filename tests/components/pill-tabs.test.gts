import { describe, test, expect } from "vitest";
import { setupRenderingContext } from "ember-vitest";
import { click } from "@ember/test-helpers";
import { tracked } from "@glimmer/tracking";
import PillTabs from "#components/pill-tabs/pill-tabs";

const OPTIONS = ["a", "b", "c"] as const;
type Option = (typeof OPTIONS)[number];

class TabState {
  @tracked selected: Option = "a";
  onChange = (v: Option) => {
    this.selected = v;
  };
}

describe("PillTabs", () => {
  test("renders all options as tabs", async () => {
    await using ctx = await setupRenderingContext();
    const state = new TabState();

    await ctx.render(
      // @ts-expect-error -- TemplateOnlyComponent type mismatch in ember-vitest ctx.render
      <template>
        <PillTabs @options={{OPTIONS}} @selected={{state.selected}} @onChange={{state.onChange}} />
      </template>,
    );

    const tabs = ctx.element.querySelectorAll("[role='tab']");
    expect(tabs.length).toBe(3);
    expect(tabs[0]?.textContent?.trim()).toBe("a");
    expect(tabs[1]?.textContent?.trim()).toBe("b");
    expect(tabs[2]?.textContent?.trim()).toBe("c");
  });

  test("selected tab has active class", async () => {
    await using ctx = await setupRenderingContext();
    const state = new TabState();
    state.selected = "b";

    await ctx.render(
      // @ts-expect-error -- TemplateOnlyComponent type mismatch in ember-vitest ctx.render
      <template>
        <PillTabs @options={{OPTIONS}} @selected={{state.selected}} @onChange={{state.onChange}} />
      </template>,
    );

    const activeTab = ctx.element.querySelector("[role='tab'][aria-selected]");
    expect(activeTab?.textContent?.trim()).toBe("b");
  });

  test("clicking a tab calls onChange with the option value", async () => {
    await using ctx = await setupRenderingContext();
    const state = new TabState();

    await ctx.render(
      // @ts-expect-error -- TemplateOnlyComponent type mismatch in ember-vitest ctx.render
      <template>
        <PillTabs @options={{OPTIONS}} @selected={{state.selected}} @onChange={{state.onChange}} />
      </template>,
    );

    const tabs = ctx.element.querySelectorAll("[role='tab']");
    await click(tabs[2] as HTMLElement);

    expect(state.selected).toBe("c");
  });

  test("renders with aria-label when @label is provided", async () => {
    await using ctx = await setupRenderingContext();
    const state = new TabState();
    const label = "My tabs";

    await ctx.render(
      // @ts-expect-error -- TemplateOnlyComponent type mismatch in ember-vitest ctx.render
      <template>
        <PillTabs
          @options={{OPTIONS}}
          @selected={{state.selected}}
          @onChange={{state.onChange}}
          @label={{label}}
        />
      </template>,
    );

    const tablist = ctx.element.querySelector("[role='tablist']");
    expect(tablist?.getAttribute("aria-label")).toBe("My tabs");
  });
});
