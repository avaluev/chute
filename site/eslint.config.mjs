import { defineConfig, globalIgnores } from "eslint/config";
import nextVitals from "eslint-config-next/core-web-vitals";
import nextTs from "eslint-config-next/typescript";

const eslintConfig = defineConfig([
  ...nextVitals,
  ...nextTs,
  // Override default ignores of eslint-config-next.
  globalIgnores([
    // Default ignores of eslint-config-next:
    ".next/**",
    "out/**",
    "build/**",
    "next-env.d.ts",
  ]),
  // The gate scripts report with `condition ? ok(...) : bad(...)`, used ~40 times across the
  // two files. It is a deliberate house style, not an accident, and every hit is a real call —
  // so the rule fires on correct code. Twelve permanent warnings train everyone to read `npm
  // run lint` as "always noisy", which is how a genuine one gets missed; the rule is scoped off
  // where the idiom lives instead of being suppressed globally.
  {
    files: ["scripts/**/*.mjs"],
    rules: { "@typescript-eslint/no-unused-expressions": "off" },
  },
]);

export default eslintConfig;
