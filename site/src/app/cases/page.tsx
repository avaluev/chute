import type { Metadata } from "next";
import { Header, Footer } from "@/components/chrome";
import { CasesGrid } from "@/components/cases-grid";
import { CASES, PAID, FREE, minutesPerDay } from "@/lib/cases";
import { CONFIG } from "@/lib/config";

export const metadata: Metadata = {
  title: "Every job Chute does — Chute",
  description:
    "All 25 jobs, what each one costs you by hand, and which of them need the app.",
  alternates: { canonical: `https://${CONFIG.domain}/cases/` },
};

export default function CasesIndex() {
  return (
    <main className="min-h-screen">
      <Header />
      <div className="mx-auto w-full max-w-5xl px-6 pt-16">
        <h1 className="font-[family-name:var(--font-mono-loaded)] text-3xl font-semibold tracking-tight">
          Everything it does, and what each one costs you
        </h1>
        <p className="mt-4 max-w-2xl text-lg text-muted-foreground">
          {CASES.length} jobs, measured rather than described. {PAID.length} of them need the
          app — {minutesPerDay(PAID)} minutes a day between them. The other {FREE.length} are the
          free command-line tool, and they account for {minutesPerDay(FREE)}.
        </p>
        <p className="mt-3 max-w-2xl text-sm text-muted-foreground">
          Every figure comes from the same ledger the product was built against, and the site
          refuses to publish if one of them stops matching it.
        </p>

        <div className="mt-12">
          <CasesGrid cases={CASES} />
        </div>
      </div>
      <Footer />
    </main>
  );
}
