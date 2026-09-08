import Link from "next/link";
import { CONFIG } from "@/lib/config";

/** The mark, drawn rather than typed: U+2913 has no glyph in JetBrains Mono and renders as a
 *  tofu box. Same shape as the app icon and the OG card. */
export function Mark({ size = 16 }: { size?: number }) {
  const w = size, h = size;
  return (
    <svg width={w} height={h} viewBox="0 0 24 24" fill="none" aria-hidden="true">
      <path d="M4 4 L9 17" stroke="var(--color-accent-chute)" strokeWidth="2" strokeLinecap="round" />
      <path d="M20 4 L15 17" stroke="var(--color-accent-chute)" strokeWidth="2" strokeLinecap="round" />
      <path d="M9 17.5 L15 17.5" stroke="var(--color-glow)" strokeWidth="2.5" strokeLinecap="round" />
      <rect x="10.5" y="7" width="3" height="4" fill="var(--color-paper)" />
    </svg>
  );
}

export function Header() {
  return (
    <header className="mx-auto w-full max-w-5xl px-6 pt-10">
      <div className="flex items-center justify-between">
        <Link href="/" className="flex items-center gap-2 font-[family-name:var(--font-mono-loaded)] text-sm font-semibold">
          <Mark /> Chute
        </Link>
        <nav className="flex items-center gap-5 text-sm text-muted-foreground">
          <Link href="/cases" className="hover:text-foreground">What it does</Link>
          <Link href="/cli" className="hover:text-foreground">CLI</Link>
          <a href={CONFIG.repo} className="hidden hover:text-foreground sm:inline">GitHub</a>
          <Link href="/docs" className="hover:text-foreground">Commands</Link>
          <a href={CONFIG.download} className="text-foreground hover:text-[var(--color-accent-chute)]">Download</a>
        </nav>
      </div>
    </header>
  );
}

export function Footer() {
  return (
    <footer className="mx-auto w-full max-w-5xl px-6 pb-16 pt-24">
      <div className="border-t border-border pt-8">
        <div className="flex flex-col gap-4 text-sm text-muted-foreground sm:flex-row sm:justify-between">
          <span>
            Chute — drop context into your agent.
            <br />
            <span className="text-xs">
              Free and MIT. © {new Date().getFullYear()} Alexandr Valuev ·{" "}
              <a className="hover:text-foreground" href={`mailto:${CONFIG.contact}`}>{CONFIG.contact}</a>
              <br />
              <a className="hover:text-foreground" href={CONFIG.social.github}>GitHub</a>
              {" · "}
              <a className="hover:text-foreground" href={CONFIG.social.linkedin}>LinkedIn</a>
              {" · "}
              <a className="hover:text-foreground" href={CONFIG.social.telegram}>Telegram</a>
            </span>
          </span>
          {/* /buy and /refunds are gone with the price. They existed for Paddle's domain
              review, and there is no Paddle. */}
          <nav className="flex flex-wrap gap-x-5 gap-y-2">
            <Link className="hover:text-foreground" href="/cases">What it does</Link>
            <Link className="hover:text-foreground" href="/cli">CLI</Link>
            <Link className="hover:text-foreground" href="/docs">Commands</Link>
            <Link className="hover:text-foreground" href="/building-with-agents">How it was built</Link>
            <a className="hover:text-foreground" href={CONFIG.repo}>Source</a>
            <Link className="hover:text-foreground" href="/support">Support</Link>
            <Link className="hover:text-foreground" href="/privacy">Privacy</Link>
            <Link className="hover:text-foreground" href="/terms">Terms</Link>
          </nav>
        </div>
      </div>
    </footer>
  );
}

/** Shared shell for every page that is not the landing page. */
export function Page({ title, lead, children }: {
  title: string; lead?: string; children: React.ReactNode;
}) {
  return (
    <main className="min-h-screen">
      <Header />
      <div className="mx-auto w-full max-w-3xl px-6 pt-16">
        <h1 className="font-[family-name:var(--font-mono-loaded)] text-3xl font-semibold tracking-tight">
          {title}
        </h1>
        {lead && <p className="mt-4 text-lg text-muted-foreground">{lead}</p>}
        <div className="mt-12 space-y-6 text-[15px] leading-relaxed text-muted-foreground">
          {children}
        </div>
      </div>
      <Footer />
    </main>
  );
}

export function H2({ children }: { children: React.ReactNode }) {
  return (
    <h2 className="pt-6 font-[family-name:var(--font-mono-loaded)] text-lg font-semibold text-foreground">
      {children}
    </h2>
  );
}
