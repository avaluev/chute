import type { Metadata } from "next";
import { Page, H2 } from "@/components/chrome";
import { CopyLine } from "@/components/copy-line";
import { InstallCli } from "@/components/install-cli";
import { CONFIG } from "@/lib/config";
import commands from "@/lib/commands.json";

export const metadata: Metadata = {
  title: "Commands — Chute",
  description: "Every Chute command, what it does, and the flags that matter. All free, all MIT.",
};

/** Generated from README.md by brand/gen-commands.mjs — one source, so this page cannot drift. */
export default function Docs() {
  return (
    <Page title="Every command"
          lead="All of these are free and MIT licensed. Nothing on this page needs a licence key.">
      <InstallCli />

      <H2>The loop</H2>
      <pre className="overflow-x-auto rounded-[var(--radius)] border border-border bg-card p-5 font-[family-name:var(--font-mono-loaded)] text-[13px] leading-relaxed text-foreground">
{`# context in
chute paths src/*.ts              # clean absolute paths → clipboard
chute bundle src/ --format xml    # every file's contents in one blob + token count
chute tokens src/                 # will this fit the window?

# work safely
chute checkpoint .                # snapshot everything, including untracked files
chute sandbox spike-auth --yolo   # folder + git + CLAUDE.md + terminal running claude

# artifacts out
chute unpack                      # a multi-file answer on the clipboard → real files
chute new                         # clipboard → a correctly named, correctly typed file
chute diff . --copy               # what did the agent actually change?`}
      </pre>

      <H2>Reference</H2>
      <div className="overflow-x-auto">
        <table className="w-full border-collapse text-left text-sm">
          <thead>
            <tr className="border-b border-border">
              <th className="py-3 pr-6 font-[family-name:var(--font-mono-loaded)] font-semibold text-foreground">Command</th>
              <th className="py-3 font-[family-name:var(--font-mono-loaded)] font-semibold text-foreground">Does</th>
            </tr>
          </thead>
          <tbody>
            {commands.map((c) => (
              <tr key={c.cmd} className="border-b border-border/50 align-top">
                <td className="whitespace-nowrap py-3 pr-6 font-[family-name:var(--font-mono-loaded)] text-[13px] text-foreground">
                  {c.cmd}
                </td>
                <td className="py-3">{c.does}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
      <p className="text-sm">
        Add <code className="text-foreground">--no-copy</code> to any command to leave the
        clipboard untouched. <code className="text-foreground">chute doctor</code> checks every
        prerequisite and prints the exact fix for anything missing.
      </p>
    </Page>
  );
}
