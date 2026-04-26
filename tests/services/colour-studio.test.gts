import { describe, expect } from "vitest";
import { test } from "ember-vitest";
import App from "#app/app";
import type ColourStudio from "#services/colour-studio";
import { DEFAULT_COLOURS } from "#utils/colours";
import type { ColourDefinition } from "#utils/colours";

const red: ColourDefinition = { name: "red", lightness: 0.637, chroma: 0.237, hue: 25 };
const blue: ColourDefinition = { name: "blue", lightness: 0.546, chroma: 0.232, hue: 264 };

describe("ColourStudio", () => {
  // eslint-disable-next-line no-empty-pattern
  test.scoped({ app: ({}, use) => use(App) });

  describe("allColours", () => {
    test("includes all DEFAULT_COLOURS", ({ context }) => {
      const studio = context.owner.lookup("service:colour-studio") as ColourStudio;
      expect(studio.allColours.length).toBeGreaterThanOrEqual(DEFAULT_COLOURS.length);
    });

    test("includes custom colours after addCustomColour", ({ context }) => {
      const studio = context.owner.lookup("service:colour-studio") as ColourStudio;
      studio.addCustomColour(red);
      expect(studio.allColours.some((c) => c.name === "red")).toBe(true);
    });
  });

  describe("existingNames", () => {
    test("contains names of all default colours", ({ context }) => {
      const studio = context.owner.lookup("service:colour-studio") as ColourStudio;
      expect(studio.existingNames).toContain("red");
      expect(studio.existingNames).toContain("blue");
    });
  });

  describe("toggleColour", () => {
    test("activates a colour when not active", ({ context }) => {
      const studio = context.owner.lookup("service:colour-studio") as ColourStudio;
      studio.toggleColour(red);
      expect(studio.activeColours.length).toBe(1);
      expect(studio.activeColours[0]!.definition.name).toBe("red");
    });

    test("deactivates a colour when already active", ({ context }) => {
      const studio = context.owner.lookup("service:colour-studio") as ColourStudio;
      studio.toggleColour(red);
      studio.toggleColour(red);
      expect(studio.activeColours.length).toBe(0);
    });

    test("toggling two colours activates both", ({ context }) => {
      const studio = context.owner.lookup("service:colour-studio") as ColourStudio;
      studio.toggleColour(red);
      studio.toggleColour(blue);
      expect(studio.activeColours.length).toBe(2);
    });
  });

  describe("addCustomColour", () => {
    test("adds to customColours and immediately activates it", ({ context }) => {
      const studio = context.owner.lookup("service:colour-studio") as ColourStudio;
      studio.addCustomColour(red);
      expect(studio.customColours.length).toBe(1);
      expect(studio.activeColours.length).toBe(1);
      expect(studio.activeColours[0]!.definition.name).toBe("red");
    });
  });

  describe("hasActiveColours", () => {
    test("is false when nothing is active", ({ context }) => {
      const studio = context.owner.lookup("service:colour-studio") as ColourStudio;
      expect(studio.hasActiveColours).toBe(false);
    });

    test("is true after activating a colour", ({ context }) => {
      const studio = context.owner.lookup("service:colour-studio") as ColourStudio;
      studio.toggleColour(red);
      expect(studio.hasActiveColours).toBe(true);
    });
  });

  describe("tokens", () => {
    test("returns empty array when no colours active", ({ context }) => {
      const studio = context.owner.lookup("service:colour-studio") as ColourStudio;
      expect(studio.tokens).toEqual([]);
    });

    test("returns tokens for the active colour", ({ context }) => {
      const studio = context.owner.lookup("service:colour-studio") as ColourStudio;
      studio.toggleColour(red);
      expect(studio.tokens.every((t) => t.name === "red")).toBe(true);
      expect(studio.tokens.length).toBeGreaterThan(0);
    });
  });

  describe("tokensFor", () => {
    test("returns only tokens for the named colour", ({ context }) => {
      const studio = context.owner.lookup("service:colour-studio") as ColourStudio;
      studio.toggleColour(red);
      studio.toggleColour(blue);
      const redTokens = studio.tokensFor("red");
      expect(redTokens.every((t) => t.name === "red")).toBe(true);
      expect(redTokens.length).toBeGreaterThan(0);
    });

    test("returns empty array for an inactive colour", ({ context }) => {
      const studio = context.owner.lookup("service:colour-studio") as ColourStudio;
      expect(studio.tokensFor("red")).toEqual([]);
    });
  });

  describe("setInterpolationMode", () => {
    test("updates interpolationMode", ({ context }) => {
      const studio = context.owner.lookup("service:colour-studio") as ColourStudio;
      studio.setInterpolationMode("oklab");
      expect(studio.interpolationMode).toBe("oklab");
    });

    test("updates interpolationMode on all active colours", ({ context }) => {
      const studio = context.owner.lookup("service:colour-studio") as ColourStudio;
      studio.toggleColour(red);
      studio.toggleColour(blue);
      studio.setInterpolationMode("lch");
      expect(studio.activeColours.every((a) => a.interpolationMode === "lch")).toBe(true);
    });
  });

  describe("css", () => {
    test("returns empty :root block when nothing active", ({ context }) => {
      const studio = context.owner.lookup("service:colour-studio") as ColourStudio;
      expect(studio.css).toBe(":root {\n}\n");
    });

    test("returns CSS with custom properties when colours active", ({ context }) => {
      const studio = context.owner.lookup("service:colour-studio") as ColourStudio;
      studio.toggleColour(red);
      expect(studio.css).toContain("--color-red-");
      expect(studio.css).toContain(":root");
    });
  });
});
