Here is the rate limiter, split across three files.

**src/rate/limit.ts**

```ts
import { counts } from "./store";

export function allow(key: string, max: number) {
  const hits = counts.get(key) ?? 0;
  if (hits >= max) return false;
  counts.set(key, hits + 1);
  return true;
}
```

**src/rate/store.ts**

```ts
export const counts = new Map<string, number>();
```

**tests/rate.test.ts**

```ts
import { allow } from "../src/rate/limit";

test("blocks past the limit", () => {
  expect(allow("a", 1)).toBe(true);
  expect(allow("a", 1)).toBe(false);
});
```
