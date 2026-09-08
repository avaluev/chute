import type { Metadata } from "next";
import { JetBrains_Mono, Instrument_Sans } from "next/font/google";
import "./globals.css";

/**
 * Mono headings, because the buyer lives in a terminal and the page should look like it was made
 * by someone who does too. Explicitly NOT Geist or Inter with neutral greys — that pairing is the
 * generated-landing-page look, and this audience recognises it instantly.
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
    <html lang="en">
      <body className={`${mono.variable} ${sans.variable} antialiased bg-background text-foreground`}>
        {children}
      </body>
    </html>
  );
}
