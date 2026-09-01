import fs from "node:fs";
import path from "node:path";
import type { Metadata } from "next";
import { marked } from "marked";
import { Header, Footer } from "@/components/chrome";
import { CONFIG } from "@/lib/config";

/**
 * ONE SOURCE, RENDERED — not a second copy of the article.
 *
 * The canonical text is `marketing/11-BUILDING-WITH-AGENTS.md`, which is also what a person
 * cloning the repository reads. Re-typing it as JSX would create the exact failure this whole
 * site's gate suite is about: two copies of a claim, drifting from the moment one is edited.
 * It is read at build time — `output: "export"` means this runs once, on the build machine, and
 * ships as static HTML.
 *
 * The H1 and the byline are lifted out of the markdown and rendered as page furniture, so the
 * document has exactly one <h1> and the article body starts at <h2>.
 */
const SOURCE = path.join(process.cwd(), "..", "marketing", "11-BUILDING-WITH-AGENTS.md");

function article() {
  const raw = fs.readFileSync(SOURCE, "utf8");
  const title = raw.match(/^# (.+)$/m)?.[1] ?? "The harness is the product";
  const lead = raw.match(/^\*\*(.+?)\*\*$/m)?.[1] ?? "";
  // Everything up to the first horizontal rule is the title block, already rendered above.
  const body = raw.slice(raw.indexOf("\n---\n") + 5);
  return { title, lead, html: marked.parse(body, { gfm: true, async: false }) as string };
}

const { title, lead } = article();

export const metadata: Metadata = {
  title: `${title} — Chute`,
  description:
    "How one developer built a macOS app with coding agents: the five ways a green test suite lied, " +
    "the ratchet that stops untestable code accumulating, and the rule that gates must read the artifact " +
    "rather than a document someone maintains.",
  openGraph: {
    title: `${title} — Chute`,
    description: lead,
    type: "article",
  },
};

export default function BuildingWithAgents() {
  const { html } = article();
  return (
    <main className="min-h-screen">
      <Header />
      <div className="mx-auto w-full max-w-3xl px-6 pt-16">
        <h1 className="font-[family-name:var(--font-mono-loaded)] text-3xl font-semibold tracking-tight">
          {title}
        </h1>
        <p className="mt-4 text-lg text-muted-foreground">{lead}</p>
        <p className="mt-3 text-sm text-muted-foreground">
          Alexandr Valuev · 2 September 2026 · every claim names the file or command that produces
          it ·{" "}
          <a className="text-foreground underline underline-offset-4" href={CONFIG.repo}>
            read the repository
          </a>
        </p>
        <div className="article mt-12" dangerouslySetInnerHTML={{ __html: html }} />
      </div>
      <Footer />
    </main>
  );
}
