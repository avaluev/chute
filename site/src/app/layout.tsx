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
  title: "Chute — drop context into your agent",
  description:
    "A macOS utility for people who drive coding agents all day. Turn a Finder selection into "
    + "agent-ready context, turn agent output back into files, and see which agent is waiting for you.",
  openGraph: {
    title: "Chute — drop context into your agent",
    description: "Select files in Finder. Get agent-ready context. Paste an answer back. Get real files.",
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
