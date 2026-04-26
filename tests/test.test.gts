import { describe, test, expect } from "vitest";
import { setupRenderingContext } from "ember-vitest";

describe("example", () => {
  test("it works", async () => {
    await using ctx = await setupRenderingContext();

    await ctx.render(
      // @ts-expect-error -- TemplateOnlyComponent type mismatch in ember-vitest ctx.render
      <template>hello there</template>,
    );

    expect(ctx.element.textContent).contains("hello there");
  });
});
