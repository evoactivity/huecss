import { describe, test, expect } from "vitest";
import { hexToOklch } from "#utils/colour-convert";

describe("hexToOklch", () => {
  test("white (#ffffff) has L near 1, C near 0", () => {
    const result = hexToOklch("#ffffff");
    expect(result).not.toBeNull();
    expect(result!.l).toBeCloseTo(1, 2);
    expect(result!.c).toBeCloseTo(0, 3);
  });

  test("black (#000000) has L near 0, C near 0", () => {
    const result = hexToOklch("#000000");
    expect(result).not.toBeNull();
    expect(result!.l).toBeCloseTo(0, 2);
    expect(result!.c).toBeCloseTo(0, 3);
  });

  test("red (#ff0000) has hue in the red range (~29deg)", () => {
    const result = hexToOklch("#ff0000");
    expect(result).not.toBeNull();
    expect(result!.l).toBeGreaterThan(0.4);
    expect(result!.c).toBeGreaterThan(0.2);
    expect(result!.h).toBeGreaterThan(20);
    expect(result!.h).toBeLessThan(40);
  });

  test("blue (#0000ff) has hue in the blue range (~264deg)", () => {
    const result = hexToOklch("#0000ff");
    expect(result).not.toBeNull();
    expect(result!.h).toBeGreaterThan(250);
    expect(result!.h).toBeLessThan(280);
  });

  test("returns null for invalid input", () => {
    expect(hexToOklch("notahex")).toBeNull();
    expect(hexToOklch("")).toBeNull();
  });

  test("L is always clamped to 0-1", () => {
    const result = hexToOklch("#ffffff");
    expect(result!.l).toBeLessThanOrEqual(1);
    expect(result!.l).toBeGreaterThanOrEqual(0);
  });

  test("h is always a number (no NaN for achromatic)", () => {
    const result = hexToOklch("#808080");
    expect(result).not.toBeNull();
    expect(isNaN(result!.h)).toBe(false);
  });

  test("h is in 0-360 range for chromatic colours", () => {
    const colours = ["#ff0000", "#00ff00", "#0000ff", "#ffff00", "#ff00ff"];
    for (const hex of colours) {
      const result = hexToOklch(hex);
      expect(result!.h).toBeGreaterThanOrEqual(0);
      expect(result!.h).toBeLessThan(360);
    }
  });

  test("accepts 3-digit hex", () => {
    const short = hexToOklch("#f00");
    const full = hexToOklch("#ff0000");
    expect(short).not.toBeNull();
    expect(short!.h).toBeCloseTo(full!.h, 1);
  });

  test("accepts hex without leading #", () => {
    const result = hexToOklch("ff0000");
    expect(result).not.toBeNull();
  });
});
