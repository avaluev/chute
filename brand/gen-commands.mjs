#!/usr/bin/env node
// README.md's command table → site/src/lib/commands.json
//
// One source, not two. A docs page hand-copied from the README is out of date by the next
// release, and a command list that lies is worse than no command list.
import { readFileSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
const readme = readFileSync(join(here, "..", "README.md"), "utf8");

// The table under "## Every command": | `chute x <args>` | what it does |
const rows = [...readme.matchAll(/^\|\s*`([^`]+)`\s*\|\s*(.+?)\s*\|\s*$/gm)]
  .map(([, cmd, does]) => ({ cmd, does: does.replace(/`/g, "") }))
  .filter((r) => r.cmd.startsWith("chute "));

if (rows.length < 20) {
  console.error(`gen-commands: only found ${rows.length} commands — the README table shape changed`);
  process.exit(1);
}

writeFileSync(join(here, "..", "site", "src", "lib", "commands.json"), JSON.stringify(rows, null, 2) + "\n");
console.log(`site/src/lib/commands.json ← README.md (${rows.length} commands)`);
