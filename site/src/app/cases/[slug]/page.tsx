import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { buttonVariants } from "@/components/ui/button";
import { CopyLine } from "@/components/copy-line";
import { Header, Footer } from "@/components/chrome";
import { SurfaceBadge, DailyCost, Demo } from "@/components/case-bits";
import { CASES, bySlug } from "@/lib/cases";
import { CONFIG } from "@/lib/config";

/**
 * One page per job, generated from lib/cases.ts.
 *
 * These are the SEO surface. Someone searching "paste multiple files into claude code" is
 * describing their own afternoon, so the H1 IS the pain in their words — not a product name and
 * not a command. They land on a recording of the thing they were about to go and do by hand.
 */
export function generateStaticParams() {
  return CASES.map((c) => ({ slug: c.slug }));
}

export async function generateMetadata(
  { params }: { params: Promise<{ slug: string }> },
): Promise<Metadata> {
  const { slug } = await params;
  const c = bySlug(slug);
  if (!c) return {};
  return {
    title: `${c.pain} — Chute`,
    description: c.fix,
    alternates: { canonical: `https://${CONFIG.domain}/cases/${c.slug}/` },
  };
}

export default async function CasePage({ params }: { params: Promise<{ slug: string }> }) {
  const { slug } = await params;
  const c = bySlug(slug);
  if (!c) notFound();

  const i = CASES.findIndex((x) => x.slug === slug);
  const prev = CASES[i - 1];
  const next = CASES[i + 1];

  return (
    <main className="min-h-screen">
      <Header />
      <article className="mx-auto w-full max-w-3xl px-6 pt-16">
        <SurfaceBadge paid={c.paid} />
        <h1 className="mt-5 font-[family-name:var(--font-mono-loaded)] text-3xl font-semibold leading-tight tracking-tight">
          {c.pain}
        </h1>

        <section className="mt-10 space-y-3">
          <h2 className="font-[family-name:var(--font-mono-loaded)] text-sm uppercase tracking-wider text-muted-foreground">
            What you do now
          </h2>
          <p className="text-[15px] leading-relaxed text-muted-foreground">{c.ritual}</p>
        </section>

        <section className="mt-10 space-y-4">
          <h2 className="font-[family-name:var(--font-mono-loaded)] text-sm uppercase tracking-wider text-muted-foreground">
            What happens instead
          </h2>
          <p className="text-[15px] leading-relaxed text-foreground">{c.fix}</p>
          <Demo c={c} />
        </section>

        <section className="mt-10 space-y-3">
          <h2 className="font-[family-name:var(--font-mono-loaded)] text-sm uppercase tracking-wider text-muted-foreground">
            What it costs you
          </h2>
          <DailyCost c={c} />
        </section>

        <section className="mt-10 space-y-3">
          <h2 className="font-[family-name:var(--font-mono-loaded)] text-sm uppercase tracking-wider text-muted-foreground">
            {c.paid ? "The same thing from the terminal" : "How to do it"}
          </h2>
          <CopyLine text={c.command} />
          {c.paid ? (
            <p className="text-sm text-muted-foreground">
              This command is free and always will be. The {CONFIG.price} buys the right-click —
              you do it where the files already are, without leaving Finder or typing a path.
            </p>
          ) : (
            <p className="text-sm text-muted-foreground">
              Free, MIT, and it never expires. Nothing on this page is behind the paid app.
            </p>
          )}
        </section>

        <div className="mt-14 flex flex-wrap items-center gap-4 border-t border-border pt-8">
          <a href={CONFIG.download} className={buttonVariants({ size: "lg" })}>
            Download — free {CONFIG.trialDays} days
          </a>
          <span className="text-sm text-muted-foreground">
            {CONFIG.price} once after that. No subscription, no account.
          </span>
        </div>

        <nav className="mt-12 flex justify-between gap-6 border-t border-border pt-6 text-sm">
          {prev ? (
            <Link href={`/cases/${prev.slug}`} className="max-w-[45%] text-muted-foreground hover:text-foreground">
              ← {prev.pain}
            </Link>
          ) : <span />}
          {next ? (
            <Link href={`/cases/${next.slug}`} className="max-w-[45%] text-right text-muted-foreground hover:text-foreground">
              {next.pain} →
            </Link>
          ) : <span />}
        </nav>

        <p className="mt-10 text-sm">
          <Link href="/cases" className="text-muted-foreground hover:text-foreground">
            All {CASES.length} of them →
          </Link>
        </p>
      </article>
      <Footer />
    </main>
  );
}
