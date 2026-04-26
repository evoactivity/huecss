import { describe, test, expect } from "vitest";
import { parseHex, hexToOklch } from "#utils/colour-convert";

describe("parseHex", () => {
  test("parses 6-digit hex", () => {
    expect(parseHex("#ff0000")).toEqual({ r: 255, g: 0, b: 0 });
    expect(parseHex("ff0000")).toEqual({ r: 255, g: 0, b: 0 });
  });

  test("parses 3-digit hex by expanding", () => {
    expect(parseHex("#f00")).toEqual({ r: 255, g: 0, b: 0 });
  });

  test("parses 8-digit hex ignoring alpha", () => {
    expect(parseHex("#ff0000ff")).toEqual({ r: 255, g: 0, b: 0 });
  });

  test("returns null for invalid hex", () => {
    expect(parseHex("nope")).toBeNull();
    expect(parseHex("#gg0000")).toBeNull();
    expect(parseHex("")).toBeNull();
  });
});

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

  test("red (#ff0000) has hue in the red range (around 29deg)", () => {
    const result = hexToOklch("#ff0000");
    expect(result).not.toBeNull();
    expect(result!.l).toBeGreaterThan(0.4);
    expect(result!.c).toBeGreaterThan(0.2);
    // Red hue in oklch is around 29 degrees
    expect(result!.h).toBeGreaterThan(20);
    expect(result!.h).toBeLessThan(40);
  });

  test("blue (#0000ff) has hue in the blue range (around 264deg)", () => {
    const result = hexToOklch("#0000ff");
    expect(result).not.toBeNull();
    expect(result!.h).toBeGreaterThan(250);
    expect(result!.h).toBeLessThan(280);
  });

  test("returns null for invalid input", () => {
    expect(hexToOklch("notahex")).toBeNull();
  });

  test("L is always clamped to 0-1", () => {
    const result = hexToOklch("#ffffff");
    expect(result!.l).toBeLessThanOrEqual(1);
    expect(result!.l).toBeGreaterThanOrEqual(0);
  });

  test("h is always in 0-360 range", () => {
    const colours = ["#ff0000", "#00ff00", "#0000ff", "#ffff00", "#ff00ff"];
    for (const hex of colours) {
      const result = hexToOklch(hex);
      expect(result!.h).toBeGreaterThanOrEqual(0);
      expect(result!.h).toBeLessThan(360);
    }
  });
});
