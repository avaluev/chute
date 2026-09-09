import type { Metadata } from "next";
import { Header, Footer } from "@/components/chrome";
import { CasesGrid } from "@/components/cases-grid";
import { CASES, PAID, FREE, minutesPerDay } from "@/lib/cases";
import { CONFIG } from "@/lib/config";

export const metadata: Metadata = {
  title: "Everything Chute does — Chute",
  description:
    "What it does, what each one costs you by hand, and which of it needs the app.",
  alternates: { canonical: `https://${CONFIG.domain}/cases/` },
};

export default function CasesIndex() {
  return (
    <main className="min-h-screen">
      <Header />
      <div className="mx-auto w-full max-w-5xl px-6 pt-16">
        <h1 className="text-3xl font-semibold leading-[1.05] tracking-[-0.035em] md:text-5xl">
          Everything it does, and what each one costs you
        </h1>
        <p className="mt-4 max-w-2xl text-xl text-muted-foreground">
          Measured, not guessed at: how often each one happens, how long it takes by hand, how
          long it takes instead. The ones that need the app add up to {minutesPerDay(PAID)}{" "}
          minutes a day; the free command-line tool accounts for another {minutesPerDay(FREE)}.
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
