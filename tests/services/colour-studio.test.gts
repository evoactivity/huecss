import { describe, test, expect } from "vitest";
import { setupRenderingContext } from "ember-vitest";
import App from "#app/app";
import type ColourStudio from "#services/colour-studio";
import { DEFAULT_COLOURS } from "#utils/colours";
import type { ColourDefinition } from "#utils/colours";

const red: ColourDefinition = { name: "red", lightness: 0.637, chroma: 0.237, hue: 25 };
const blue: ColourDefinition = { name: "blue", lightness: 0.546, chroma: 0.232, hue: 264 };

describe("ColourStudio", () => {
  describe("allColours", () => {
    test("includes all DEFAULT_COLOURS", async () => {
      await using ctx = await setupRenderingContext(App);
      const s = ctx.owner.lookup("service:colour-studio") as ColourStudio;
      expect(s.allColours.length).toBeGreaterThanOrEqual(DEFAULT_COLOURS.length);
    });

    test("includes custom colours after addCustomColour", async () => {
      await using ctx = await setupRenderingContext(App);
      const s = ctx.owner.lookup("service:colour-studio") as ColourStudio;
      s.addCustomColour(red);
      expect(s.allColours.some((c) => c.name === "red")).toBe(true);
    });
  });

  describe("existingNames", () => {
    test("contains names of all default colours", async () => {
      await using ctx = await setupRenderingContext(App);
      const s = ctx.owner.lookup("service:colour-studio") as ColourStudio;
      expect(s.existingNames).toContain("red");
      expect(s.existingNames).toContain("blue");
    });
  });

  describe("toggleColour", () => {
    test("activates a colour when not active", async () => {
      await using ctx = await setupRenderingContext(App);
      const s = ctx.owner.lookup("service:colour-studio") as ColourStudio;
      s.toggleColour(red);
      expect(s.activeColours.length).toBe(1);
      expect(s.activeColours[0]!.definition.name).toBe("red");
    });

    test("deactivates a colour when already active", async () => {
      await using ctx = await setupRenderingContext(App);
      const s = ctx.owner.lookup("service:colour-studio") as ColourStudio;
      s.toggleColour(red);
      s.toggleColour(red);
      expect(s.activeColours.length).toBe(0);
    });

    test("toggling two colours activates both", async () => {
      await using ctx = await setupRenderingContext(App);
      const s = ctx.owner.lookup("service:colour-studio") as ColourStudio;
      s.toggleColour(red);
      s.toggleColour(blue);
      expect(s.activeColours.length).toBe(2);
    });
  });

  describe("addCustomColour", () => {
    test("adds to customColours and immediately activates it", async () => {
      await using ctx = await setupRenderingContext(App);
      const s = ctx.owner.lookup("service:colour-studio") as ColourStudio;
      s.addCustomColour(red);
      expect(s.customColours.length).toBe(1);
      expect(s.activeColours.length).toBe(1);
      expect(s.activeColours[0]!.definition.name).toBe("red");
    });
  });

  describe("hasActiveColours", () => {
    test("is false when nothing is active", async () => {
      await using ctx = await setupRenderingContext(App);
      const s = ctx.owner.lookup("service:colour-studio") as ColourStudio;
      expect(s.hasActiveColours).toBe(false);
    });

    test("is true after activating a colour", async () => {
      await using ctx = await setupRenderingContext(App);
      const s = ctx.owner.lookup("service:colour-studio") as ColourStudio;
      s.toggleColour(red);
      expect(s.hasActiveColours).toBe(true);
    });
  });

  describe("tokens", () => {
    test("returns empty array when no colours active", async () => {
      await using ctx = await setupRenderingContext(App);
      const s = ctx.owner.lookup("service:colour-studio") as ColourStudio;
      expect(s.tokens).toEqual([]);
    });

    test("returns tokens for the active colour", async () => {
      await using ctx = await setupRenderingContext(App);
      const s = ctx.owner.lookup("service:colour-studio") as ColourStudio;
      s.toggleColour(red);
      expect(s.tokens.every((t) => t.name === "red")).toBe(true);
      expect(s.tokens.length).toBeGreaterThan(0);
    });
  });

  describe("tokensFor", () => {
    test("returns only tokens for the named colour", async () => {
      await using ctx = await setupRenderingContext(App);
      const s = ctx.owner.lookup("service:colour-studio") as ColourStudio;
      s.toggleColour(red);
      s.toggleColour(blue);
      const redTokens = s.tokensFor("red");
      expect(redTokens.every((t) => t.name === "red")).toBe(true);
      expect(redTokens.length).toBeGreaterThan(0);
    });

    test("returns empty array for an inactive colour", async () => {
      await using ctx = await setupRenderingContext(App);
      const s = ctx.owner.lookup("service:colour-studio") as ColourStudio;
      expect(s.tokensFor("red")).toEqual([]);
    });
  });
});
