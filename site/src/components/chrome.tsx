import Link from "next/link";
import { CONFIG } from "@/lib/config";

/**
 * THE MARK — the app icon's parachute, not an abstraction of it.
 *
 * What was here before was two diagonal strokes, a bar and a small rect: a "chute" as a concept.
 * It shared nothing with the icon in the reader's Dock, which is a green scalloped canopy over a
 * white crate. A header glyph that does not match the app icon is a second logo, and a product
 * with two logos looks like a product with no art direction.
 *
 * Drawn rather than set as text: U+2913 has no glyph in JetBrains Mono and renders as tofu.
 *
 * The geometry is the icon's, simplified for 16-20px: six gores, five sagging scallops (the
 * scallops are what say parachute and not mushroom — the same note is in Scripts/make-icon.swift
 * and in MenuBarMark.swift, because all three surfaces learned it separately), four risers, and a
 * three-quarter crate with a lit lid so it reads as a box and not a square.
 *
 * Colours come from brand/tokens.json through brand.css, so this cannot drift from the icon or
 * from the site's accent.
 */
export function Mark({ size = 16 }: { size?: number }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" aria-hidden="true">
      {/* Canopy: a shallow dome closed by a scalloped hem. */}
      <path
        d="M2.4 10.3 A 9.6 7.3 0 0 1 21.6 10.3
           Q 19.68 12.5 17.76 10.3
           Q 15.84 12.5 13.92 10.3
           Q 12.00 12.5 10.08 10.3
           Q 8.16 12.5 6.24 10.3
           Q 4.32 12.5 2.4 10.3 Z"
        fill="var(--color-accent-chute)"
      />
      {/* Gore seams — the canopy is a curved surface, not a green semicircle. */}
      <g stroke="var(--color-ground-900)" strokeWidth="0.55" strokeLinecap="round" opacity="0.35">
        <path d="M12 3.05 V 11.4" />
        <path d="M12 3.4 C 9.6 4.4 7.4 6.6 6.6 11.4" />
        <path d="M12 3.4 C 14.4 4.4 16.6 6.6 17.4 11.4" />
      </g>
      {/* Risers, taut from the outer cusps to the crate's top corners. */}
      <g stroke="var(--color-accent-chute)" strokeWidth="0.85" strokeLinecap="round">
        <path d="M2.6 10.6 L 9.5 16.8" />
        <path d="M21.4 10.6 L 14.5 16.8" />
        <path d="M8.4 11.4 L 11.1 16.6" />
        <path d="M15.6 11.4 L 12.9 16.6" />
      </g>
      {/* The crate: three faces under one light, which is what makes it a box. */}
      <path d="M12 15.9 L 15.1 17.2 L 12 18.5 L 8.9 17.2 Z" fill="var(--color-paper)" />
      <path d="M8.9 17.2 L 12 18.5 L 12 21.7 L 8.9 20.4 Z" fill="var(--color-paper)" opacity="0.82" />
      <path d="M15.1 17.2 L 12 18.5 L 12 21.7 L 15.1 20.4 Z" fill="var(--color-paper)" opacity="0.58" />
    </svg>
  );
}

export function Header() {
  return (
    <header className="mx-auto w-full max-w-5xl px-6 pt-10">
      <div className="flex items-center justify-between">
        <Link href="/" className="flex items-center gap-2 font-[family-name:var(--font-mono-loaded)] text-sm font-semibold">
          <Mark size={20} /> Chute
        </Link>
        <nav className="flex items-center gap-5 text-sm text-muted-foreground">
          <Link href="/cases" className="hover:text-foreground">What it does</Link>
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
            <Link className="hover:text-foreground" href="/cli">Terminal</Link>
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
