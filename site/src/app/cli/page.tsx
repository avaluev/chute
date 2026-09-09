import type { Metadata } from "next";
import Link from "next/link";
import { CopyLine } from "@/components/copy-line";
import { InstallCli } from "@/components/install-cli";
import { Header, Footer } from "@/components/chrome";
import { CaseCard } from "@/components/case-bits";
import { FREE, minutesPerDay } from "@/lib/cases";
import { CONFIG } from "@/lib/config";

export const metadata: Metadata = {
  title: "The free command-line tool — Chute",
  description:
    "Everything the app does, from a terminal. MIT licensed, offline, no account.",
  alternates: { canonical: `https://${CONFIG.domain}/cli/` },
};

/**
 * The free half, given a page of its own rather than a paragraph on the landing page.
 *
 * It is top of funnel and it is proof: someone who will not pay $19 for a utility from a stranger
 * can read the source, run it, and decide afterwards. Hiding it would convert marginally better
 * and would cost the one thing this product is actually competing on.
 *
 * The full command table stays on /docs. Two copies of a 28-row reference is how one of them
 * goes stale, and /docs is the page Paddle's reviewer already checks.
 */
export default function CliPage() {
  return (
    <main className="min-h-screen">
      <Header />
      <div className="mx-auto w-full max-w-3xl px-6 pt-16">
        <p className="font-[family-name:var(--font-mono-loaded)] text-xs uppercase tracking-[0.18em] text-[var(--color-accent-chute)]">
          Free forever
        </p>
        <h1 className="mt-3 font-[family-name:var(--font-mono-loaded)] text-3xl font-semibold tracking-tight">
          The command-line tool is free, MIT, and yours whatever happens to this page
        </h1>
        <p className="mt-5 text-lg text-muted-foreground">
          Zero dependencies, zero telemetry, no account, under 1 MB. It does everything the app
          does, including what the Finder menu puts behind a right-click.
        </p>

        <div className="mt-8 max-w-md">
          <InstallCli />
        </div>

        <div className="mt-12 space-y-6 text-[15px] leading-relaxed text-muted-foreground">
          <p>
            There is no crippled tier, here or in the app. The Finder menu, the menu-bar switcher
            and the hotkey are free and MIT the same as{" "}
            <code className="text-foreground">chute sessions</code>,{" "}
            <code className="text-foreground">chute bundle</code> and the rest of this page.
          </p>
          <p>
            What the app adds isn&rsquo;t capability — the CLI already has it. It&rsquo;s staying
            in Finder, skipping the typed path, and seeing which session needs you without
            checking every terminal yourself.
          </p>
        </div>

        <h2 className="mt-14 font-[family-name:var(--font-mono-loaded)] text-lg font-semibold text-foreground">
          What it does on its own
        </h2>
        <p className="mt-2 text-sm text-muted-foreground">
          {minutesPerDay(FREE)} minutes a day, measured the same way as everything else.
        </p>
        <div className="mt-6 grid gap-4 sm:grid-cols-2">
          {FREE.map((c) => <CaseCard key={c.slug} c={c} />)}
        </div>

        <div className="mt-12 flex flex-wrap gap-x-6 gap-y-2 text-sm">
          <Link className="text-muted-foreground hover:text-foreground" href="/docs">
            Every command →
          </Link>
          <a className="text-muted-foreground hover:text-foreground" href={CONFIG.repo}>
            Source on GitHub →
          </a>
          <Link className="text-muted-foreground hover:text-foreground" href="/cases">
            Everything it does, free and paid →
          </Link>
        </div>
      </div>
      <Footer />
    </main>
  );
}
