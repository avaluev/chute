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
  title: "Chute — point your coding agent at the files",
  description:
    "A macOS utility for developers who drive Claude Code or Cursor all day. Select folders in "
    + "Finder, right-click once, and every file inside is on your clipboard as one blob with a "
    + "token count. $19 once, no account, no network code.",
  openGraph: {
    title: "Chute — point your coding agent at the files",
    description:
      "Your agent can read anything. You still have to tell it what. One right-click turns a "
      + "Finder selection into agent-ready context, with the token count before you paste.",
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
