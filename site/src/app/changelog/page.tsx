import type { Metadata } from "next";
import { Page } from "@/components/chrome";
import { CONFIG } from "@/lib/config";

export const metadata: Metadata = {
  title: "Changelog — Chute",
  description: "What changed, when, and why.",
};

/** Hand-maintained on purpose: a changelog generated from commit subjects is a commit log, and
 *  nobody has ever wanted to read one. Each entry says what changed for the person using it. */
// SIZES ARE BOUNDS, NOT MEASUREMENTS. A byte count in marketing copy is a claim that goes false
// on the next commit — this page said 2.5 MB for a CLI that is 809 KB, and two other pages said
// 788 KB for the same binary. A bound stays true without anyone maintaining it.
const RELEASES = [
  {
    version: "0.2.1",
    date: "2026-09-01",
    notes: [
      "The Finder menu is five rows, not eleven. Open in Terminal, Move Junk to Trash, Save Clipboard as Files, New Scratch Folder and Set Up for an Agent are gone — every one of them solved a problem a Claude Code or Cursor user does not have, because their agent already writes files and their OS already opens a terminal. The CLI still does all of it.",
      "Fixed: Copy Folder Tree gave you the tree of whichever item Finder happened to list first, not the folder you were looking at. Select thirty-four things in a Python project and you got the contents of __pycache__. It now uses the folder that contains everything you selected.",
      "Add to Context Basket: collect files across several folders while you browse, then hand the whole set over at once. Nothing else on the Mac does this.",
      "Four times faster. Copying a folder as context no longer starts a `git` subprocess to work out where the repository root is — 102.7 ms down to 24.7 ms on 40 files, and the token count went from 184.1 ms to 23.5 ms.",
      "A third smaller. Stripping symbols before signing took the app from 3.3 MB to 2.4 MB, and the download to 1.6 MB.",
      "The app now carries the entitlement it needs to talk to Finder under macOS's hardened runtime, and the Finder extension's sandbox exception is scoped to ~/.chute instead of the whole filesystem.",
      "`chute sessions` and `chute seed` now exit non-zero when they fail. Both used to report success after a permission denial or a failed write.",
    ],
  },
  {
    version: "0.2.0",
    date: "2026-08-28",
    notes: [
      "Finder right-click, renamed for clarity: Copy Full Paths, Copy Files as Context (every selected file's contents in one block, with a token count), Copy Folder Tree at three depths, Save Clipboard as Files (an agent's answer written back to disk, after you see the list), New File (empty markdown, from the clipboard, or an image), Set Up for an Agent (rules, a scratch folder, or a checkpoint), Move Junk to Trash, Open in Terminal.",
      "Icons now carry meaning: blue reads, green creates, purple prepares a folder for an agent, red changes what is already there — and red always shows you the list before it acts.",
      "Save a Checkpoint: a restore point for a folder before you let an agent run. Your worktree, index and HEAD are never touched.",
      "Menu bar: every terminal session grouped by whether it needs you, coloured per project, with per-session CPU and memory. Click a row to bring that terminal forward.",
      "Menu bar: every local server, what it is, which project it belongs to, and a way to stop it.",
      "25 CLI commands, zero dependencies, under 1 MB.",
      `${CONFIG.trialDays}-day trial, then ${CONFIG.price} once. The CLI stays free and MIT forever.`,
    ],
  },
];

export default function Changelog() {
  return (
    <Page title="Changelog" lead="What changed, when, and why.">
      {RELEASES.map((r) => (
        <section key={r.version}>
          <div className="flex items-baseline gap-4">
            <h2 className="font-[family-name:var(--font-mono-loaded)] text-lg font-semibold text-foreground">
              {r.version}
            </h2>
            <span className="text-sm">{r.date}</span>
          </div>
          <ul className="mt-4 space-y-2">
            {r.notes.map((n) => (
              <li key={n} className="pl-4 -indent-4">— {n}</li>
            ))}
          </ul>
        </section>
      ))}
      <p className="pt-6 text-sm">
        Every commit is public at{" "}
        <a className="text-foreground underline underline-offset-4" href={`${CONFIG.repo}/commits/main`}>
          {CONFIG.repo.replace("https://", "")}
        </a>.
      </p>
    </Page>
  );
}
