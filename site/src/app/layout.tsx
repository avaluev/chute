import type { Metadata } from "next";
import { JetBrains_Mono, Instrument_Sans } from "next/font/google";
import "./globals.css";

/**
 * Instrument Sans sets everything a person READS; JetBrains Mono sets only what a MACHINE said —
 * commands, paths, metrics, state words, small labels. Until 2026-09-09 the headings were mono
 * too, which is where the page got its unfinished look: mono at display size has even advance
 * widths and no optical kerning, and it cost the hero, because a 29-character line in mono cannot
 * fit a 390px phone. Demoting it took mono from 18% of the page's characters to 9%, and now the
 * monospace itself carries meaning — if it is mono, the computer said it.
 *
 * Still explicitly NOT Geist or Inter with neutral greys: that pairing is the generated-landing-
 * page look, and this audience recognises it instantly.
 *
 * BOTH ARE VARIABLE FONTS ON PURPOSE. Pinning `weight: ["400","500","600"]` builds static
 * instances and measured 8 KB smaller (69.4 KB → 61.2 KB) — and was rejected: nothing then ships
 * a real 700, so every <strong> renders as browser-synthesised faux bold. Eight kilobytes is not
 * worth smeared bold on the page whose whole problem was that the type looked wrong.
 */
const mono = JetBrains_Mono({ variable: "--font-mono-loaded", subsets: ["latin"], display: "swap" });
const sans = Instrument_Sans({ variable: "--font-sans-loaded", subsets: ["latin"], display: "swap" });

export const metadata: Metadata = {
  metadataBase: new URL("https://chutedev.com"),
  title: "Chute — see which agent is waiting for you",
  description:
    "A free, MIT-licensed macOS utility for developers who drive Claude Code, Codex or "
    + "Antigravity all day. Every agent session in your menu bar — project, agent, model and "
    + "load — and one right-click to hand an agent a folder. Offline, no telemetry, no account.",
  openGraph: {
    title: "Chute — see which agent is waiting for you",
    description:
      "Nine terminal tabs, six agents running, and no way to tell which one stopped. Chute puts "
      + "every session in your menu bar and turns a Finder selection into agent-ready context. "
      + "Free and MIT.",
    url: "https://chutedev.com",
    siteName: "Chute",
    images: ["/media/og.png"],
    type: "website",
  },
  twitter: { card: "summary_large_image", images: ["/media/og.png"] },
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    // THE FONT VARIABLES BELONG ON <html>, NOT <body>.
    //
    // next/font declares --font-sans-loaded / --font-mono-loaded on whatever element carries its
    // `.variable` class. brand.css declares --font-sans at :root — i.e. on <html> — as
    // `var(--font-sans-loaded), 'Instrument Sans', …`. With the classes on <body>, that var() was
    // being resolved one level ABOVE where it is defined, so it was invalid at :root, which makes
    // the WHOLE declaration guaranteed-invalid: --font-sans computed to the empty string, <body>
    // inherited that empty computed value (custom properties are computed where declared, not
    // re-evaluated per element), and `html { @apply font-sans }` fell all the way back to the
    // browser default serif. The entire site rendered its body copy in TIMES on 2026-09-09.
    <html lang="en" className={`${mono.variable} ${sans.variable}`}>
      <body className="antialiased bg-background text-foreground">
        {children}
      </body>
    </html>
  );
}
