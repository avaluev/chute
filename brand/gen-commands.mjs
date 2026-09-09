#!/usr/bin/env node
// docs/CLI.md's command table → site/src/lib/commands.json
//
// One source, not two. A docs page hand-copied from the reference is out of date by the next
// release, and a command list that lies is worse than no command list.
//
// It read README.md until 2026-09-09. The table lived there, which put a hundred lines of
// terminal reference — a quarter of the file — on the front page of a repository whose subject
// is a Finder menu and a menu bar. The reference moved to docs/CLI.md and the README keeps a
// pointer; this follows it, so /docs is still generated and still cannot drift.
import { readFileSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
const readme = readFileSync(join(here, "..", "docs", "CLI.md"), "utf8");

// The table under "## Every command": | `chute x <args>` | what it does |
const rows = [...readme.matchAll(/^\|\s*`([^`]+)`\s*\|\s*(.+?)\s*\|\s*$/gm)]
  .map(([, cmd, does]) => ({ cmd, does: does.replace(/`/g, "") }))
  .filter((r) => r.cmd.startsWith("chute "));

if (rows.length < 20) {
  console.error(`gen-commands: only found ${rows.length} commands — the docs/CLI.md table shape changed`);
  process.exit(1);
}

writeFileSync(join(here, "..", "site", "src", "lib", "commands.json"), JSON.stringify(rows, null, 2) + "\n");
console.log(`site/src/lib/commands.json ← docs/CLI.md (${rows.length} commands)`);
