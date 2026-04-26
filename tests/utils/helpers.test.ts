import { describe, test, expect } from "vitest";
import { eq, not, or, and } from "#utils/helpers";

describe("eq", () => {
  test("returns true for identical primitives", () => {
    expect(eq(1, 1)).toBe(true);
    expect(eq("a", "a")).toBe(true);
    expect(eq(null, null)).toBe(true);
  });

  test("returns false for different values", () => {
    expect(eq(1, 2)).toBe(false);
    expect(eq("a", "b")).toBe(false);
  });

  test("uses strict equality -- no type coercion", () => {
    expect(eq(1, "1")).toBe(false);
    expect(eq(0, false)).toBe(false);
    expect(eq(null, undefined)).toBe(false);
  });
});

describe("not", () => {
  test("negates truthy values", () => {
    expect(not(true)).toBe(false);
    expect(not(1)).toBe(false);
    expect(not("x")).toBe(false);
  });

  test("negates falsy values", () => {
    expect(not(false)).toBe(true);
    expect(not(0)).toBe(true);
    expect(not("")).toBe(true);
    expect(not(null)).toBe(true);
    expect(not(undefined)).toBe(true);
  });
});

describe("or", () => {
  test("returns true if any arg is truthy", () => {
    expect(or(false, true)).toBe(true);
    expect(or(0, 1, 0)).toBe(true);
  });

  test("returns false if all args are falsy", () => {
    expect(or(false, false)).toBe(false);
    expect(or(0, null, undefined, "")).toBe(false);
  });

  test("works with a single arg", () => {
    expect(or(true)).toBe(true);
    expect(or(false)).toBe(false);
  });
});

describe("and", () => {
  test("returns true if all args are truthy", () => {
    expect(and(true, true)).toBe(true);
    expect(and(1, "x", [])).toBe(true);
  });

  test("returns false if any arg is falsy", () => {
    expect(and(true, false)).toBe(false);
    expect(and(1, 0)).toBe(false);
  });

  test("works with a single arg", () => {
    expect(and(true)).toBe(true);
    expect(and(false)).toBe(false);
  });
});
