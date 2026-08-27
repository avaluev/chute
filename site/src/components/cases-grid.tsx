"use client";

import { useState } from "react";
import { CaseCard } from "@/components/case-bits";
import type { Case } from "@/lib/cases";

/**
 * The filter is instant and unanimated, on purpose.
 *
 * emilkowal.ski/ui/you-dont-need-animations: do not animate a frequent action, and never animate
 * what a returning visitor sees more than twice. Filtering a list is both. A 200ms fade here
 * would make the list feel slower than it is, and it would be the first thing on a page arguing
 * that seconds matter that existed only for decoration.
 */
const FILTERS = [
  { key: "all", label: "Everything" },
  { key: "paid", label: "The app" },
  { key: "free", label: "Free CLI" },
] as const;

type Key = (typeof FILTERS)[number]["key"];

export function CasesGrid({ cases }: { cases: Case[] }) {
  const [filter, setFilter] = useState<Key>("all");

  const shown = cases.filter((c) =>
    filter === "all" ? true : filter === "paid" ? c.paid : !c.paid,
  );
  const minutes =
    Math.round(shown.reduce((s, c) => s + (c.savedMinutes ?? 0), 0) * 10) / 10;

  return (
    <>
      <div className="flex flex-wrap items-center gap-2">
        {FILTERS.map((f) => (
          <button
            key={f.key}
            onClick={() => setFilter(f.key)}
            aria-pressed={filter === f.key}
            className={`rounded-[4px] border px-3 py-1.5 font-[family-name:var(--font-mono-loaded)] text-sm ${
              filter === f.key
                ? "border-[var(--color-accent-chute)] text-[var(--color-accent-chute)]"
                : "border-border text-muted-foreground hover:text-foreground"
            }`}
          >
            {f.label}
          </button>
        ))}
        <span className="ml-auto font-[family-name:var(--font-mono-loaded)] text-sm text-muted-foreground">
          {shown.length} jobs · {minutes} min a day
        </span>
      </div>

      <div className="mt-8 grid gap-4 sm:grid-cols-2">
        {shown.map((c) => (
          <CaseCard key={c.slug} c={c} />
        ))}
      </div>
    </>
  );
}
