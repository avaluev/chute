Here is the rate limiter, split across three files.

```ts
// src/rate/limit.ts
export function allow(key: string, max: number) {
  const hits = counts.get(key) ?? 0;
  if (hits >= max) return false;
  counts.set(key, hits + 1);
  return true;
}
```

```ts
// src/rate/store.ts
export const counts = new Map<string, number>();
```

```ts
// tests/rate.test.ts
import { allow } from "../src/rate/limit";

test("blocks past the limit", () => {
  expect(allow("a", 1)).toBe(true);
  expect(allow("a", 1)).toBe(false);
});
```
