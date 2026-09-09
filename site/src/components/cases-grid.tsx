"use client";

import { useState } from "react";
import { CaseCard, CaseRow } from "@/components/case-bits";
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
  // NOT "Free CLI": both surfaces are free and MIT, so pricing one of them implies the
  // other costs money. The split here is which SURFACE a job needs, never what it costs.
  { key: "free", label: "The CLI" },
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
            className={`rounded-[4px] border px-3 py-1.5 text-sm ${
              filter === f.key
                ? "border-[var(--color-accent-chute)] text-[var(--color-accent-chute)]"
                : "border-border text-muted-foreground hover:text-foreground"
            }`}
          >
            {f.label}
          </button>
        ))}
        <span className="ml-auto font-[family-name:var(--font-mono-loaded)] text-sm text-muted-foreground">
          {shown.length} shown · {minutes} min a day
        </span>
      </div>

      {/* FOUR CARDS, THEN ROWS. Ranked by the minutes each job actually saves, so the four the
          reader should look at first are the four that earn the most — not the first four the
          ledger happens to list. Cases with no figure (deliberately: see cases.ts) sort last and
          land in the rows, which is where an unquantified job belongs on a page arguing in
          minutes. Below four featured items the split stops meaning anything, so a filtered view
          that is already short just renders as cards. */}
      {(() => {
        const ranked = [...shown].sort(
          (a, b) => (b.savedMinutes ?? -1) - (a.savedMinutes ?? -1),
        );
        const featured = ranked.length > 6 ? ranked.slice(0, 4) : ranked;
        const rest = ranked.length > 6 ? ranked.slice(4) : [];
        return (
          <>
            <div className="mt-8 grid grid-cols-1 gap-4 sm:grid-cols-2">
              {featured.map((c) => (
                <CaseCard key={c.slug} c={c} />
              ))}
            </div>
            {rest.length > 0 && (
              <div className="mt-10">
                <p className="text-xs font-medium uppercase tracking-[0.14em] text-muted-foreground">
                  The other {rest.length}
                </p>
                <div className="mt-3">
                  {rest.map((c) => (
                    <CaseRow key={c.slug} c={c} />
                  ))}
                </div>
              </div>
            )}
          </>
        );
      })()}
    </>
  );
}
