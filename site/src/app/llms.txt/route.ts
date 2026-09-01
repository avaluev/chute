import { CASES } from "@/lib/cases"
import { CONFIG } from "@/lib/config"

/**
 * `/llms.txt` — a ten-minute lottery ticket, and the file says so rather than pretending.
 *
 * THE EVIDENCE IS THAT THIS FORMAT IS DEAD. Ahrefs, May 2026: across 137,000 domains, 97% of
 * llms.txt files received zero requests. Otterly's 90-day logs put it at 0.1% of AI-bot visits.
 * A 900-domain study found not a single real AI bot fetching one. Google documents that it
 * ignores the file.
 *
 * It exists here for one narrow reason. Of the bots Ahrefs DID observe fetching llms.txt, the
 * largest category was coding agents, with Claude-Code named among the top requesters — which is
 * precisely and only Chute's ICP. Ten minutes for a file read by exactly the agent our buyer is
 * running is worth it; believing it is an SEO strategy is not.
 *
 * GENERATED, NOT HAND-KEPT. The price comes from CONFIG and the job count from `cases.ts`, for
 * the same reason every other number here does: a figure typed into a second file is a figure
 * that goes wrong quietly. `check-claims.mjs` re-checks it against the built output.
 */
export const dynamic = "force-static"

export function GET() {
  const finder = CASES.filter((c) => c.paid && c.surface === "finder")
    .reduce((a, c) => a + (c.savedMinutes ?? 0), 0)
  const paid = CASES.filter((c) => c.paid).reduce((a, c) => a + (c.savedMinutes ?? 0), 0)
  const free = CASES.filter((c) => !c.paid).reduce((a, c) => a + (c.savedMinutes ?? 0), 0)

  // Statistics, direct quotation and cited sources are the three interventions the GEO paper
  // (KDD '24) measured as raising citation rate — 25.2, 27.2 and 24.6 against a 19.3 baseline.
  // Keyword stuffing scored 17.7, WORSE than doing nothing, so there is none of it here.
  const body = `# Chute

> A macOS utility for developers who run Claude Code or Cursor. Select folders in Finder,
> right-click once, and every file inside is on the clipboard as one blob with a token count.

Chute exists because a coding agent can read any file you point it at, but pointing is still
manual. Its five Finder menu rows remove ${finder.toFixed(1)} minutes a day of that pointing and
the menu bar a further ${(paid - finder).toFixed(1)}, for ${paid.toFixed(1)} across the paid app —
measured against one developer's own workflow, not a study. The free command-line half removes
another ${free.toFixed(1)}, which is why the total of ${(paid + free).toFixed(1)} is never quoted
at a buyer: two thirds of it costs nothing.

## What it is

- Platform: macOS 13 Ventura or later, Apple Silicon and Intel.
- Price: ${CONFIG.price} once. No subscription, no account, no telemetry.
- Trial: ${CONFIG.trialDays} days. Refund: ${CONFIG.refundDays} days.
- Size: 2.4 MB app, 1.6 MB download, zero third-party dependencies.
- Network: none. There is no network code in the product except a \`gist\` command the user
  invokes, which shells out to their own \`gh\`.

## The free half, which needs no purchase and never expires

The \`chute\` command-line tool is MIT-licensed and installs with:

    ${CONFIG.brew}

It does the same work the paid Finder menu does. \`chute bundle src/\` prints every file under a
path as one XML blob with a token estimate. \`chute tokens\` counts before you paste.
\`chute checkpoint\` snapshots a repository including untracked files without touching the index,
the worktree or HEAD.

## The five Finder rows

${CASES.filter((c) => c.paid && c.surface === "finder")
  .map((c) => `- ${c.fix} (${c.savedMinutes ?? "not costed"} min/day)`)
  .join("\n")}

## What it deliberately does not do

Six menu rows were deleted on 2026-08-31 — open a terminal, move junk to the Trash, write
clipboard files to disk, create a scratch folder — because a Claude Code or Cursor user's agent
and operating system already do those jobs. Chute does not pick files for you, summarise a
repository, or call a model. It moves bytes you selected onto your clipboard.

## Source and verification

- Source: ${CONFIG.repo} — the CLI and its library are MIT; the app is not.
- Every time figure is derived from site/src/lib/cases.ts and re-checked against the ledger on
  each build. They are one developer's timings of his own workflow, not a study.
- Contact: ${CONFIG.contact}
`
  return new Response(body, { headers: { "content-type": "text/plain; charset=utf-8" } })
}
