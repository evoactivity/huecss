export function eq(a: unknown, b: unknown): boolean {
  return a === b;
}

export function not(a: unknown): boolean {
  return !a;
}

export function or(...args: unknown[]): boolean {
  return args.some(Boolean);
}

export function and(...args: unknown[]): boolean {
  return args.every(Boolean);
}
