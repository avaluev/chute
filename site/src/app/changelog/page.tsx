import type { Metadata } from "next";
import { Page } from "@/components/chrome";
import { CONFIG } from "@/lib/config";

export const metadata: Metadata = {
  title: "Changelog — Chute",
  description: "What changed, when, and why.",
};

/** Hand-maintained on purpose: a changelog generated from commit subjects is a commit log, and
 *  nobody has ever wanted to read one. Each entry says what changed for the person using it. */
const RELEASES = [
  {
    version: "0.1.0",
    date: "Unreleased",
    notes: [
      "Finder right-click: copy full paths, copy files with contents (with a token count), copy a folder tree at three depths, paste an image from the clipboard, new markdown file, open in Terminal.",
      "Menu bar: every terminal session grouped by whether it needs you, coloured per project, with per-session CPU and memory. Click a row to bring that terminal forward.",
      "Menu bar: every local server, what it is, which project it belongs to, and a way to stop it.",
      "25 CLI commands, zero dependencies, 2.5 MB.",
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
