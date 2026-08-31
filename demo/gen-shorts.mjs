#!/usr/bin/env node
/**
 * A VHS tape per free-CLI case, generated from site/src/lib/cases.ts.
 *
 * WHY GENERATED: a demo whose command differs from the command printed beside it on the page is
 * the exact failure that put a GIF of `chute unpack` FAILING on the live site under a caption
 * saying it worked. Generating the tape from the same field the page renders makes that
 * impossible rather than merely unlikely.
 *
 * WHAT IS DELIBERATELY NOT FILMED — and this is a policy, not an omission:
 *   · anything that opens a window or launches an agent (a recording cannot control what it
 *     spawns, and a tape that leaves five terminals behind is not re-runnable)
 *   · anything that uploads (filming `gist` means publishing a gist on every re-record)
 *   · anything that reads real secrets (a Keychain prompt on camera, or worse, no prompt)
 * Those cases keep `demo: undefined` and the page renders them as one column, honestly.
 *
 *   node demo/gen-shorts.mjs            report only
 *   node demo/gen-shorts.mjs --write    write the tapes
 */
import { writeFileSync, mkdtempSync, rmSync } from "node:fs";
import { execFileSync } from "node:child_process";
import { tmpdir } from "node:os";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { FREE } from "../site/src/lib/cases.ts";

const HERE = dirname(fileURLToPath(import.meta.url));
const TAPES = resolve(HERE, "tapes");
const WRITE = process.argv.includes("--write");

/** Commands a recording must never actually run, with the reason stated where it is enforced. */
const UNFILMABLE = {
  "sandbox": "launches real terminals and agents — a re-record would leave five behind",
  "gist": "uploads — filming it publishes a gist every time the demos are rebuilt",
  "env": "reads the Keychain — either a permission prompt on camera, or worse, none",
};

/**
 * Commands that READ THE CLIPBOARD. A generated tape is one typed line and cannot put anything
 * on the pasteboard first, so what it films depends on whatever the operator happened to copy
 * last — which is how `chute unpack` was filmed FAILING and shipped to the live site under a
 * caption saying it worked. It also makes this script's own verification meaningless: `buf add`
 * passed here only because the machine running it had something on the clipboard.
 *
 * These get a hand-written tape with a real setup step, or no demo at all.
 */
const NEEDS_SETUP = {
  "buf": "reads the clipboard — a generated one-liner cannot put anything on it first",
};

/** Hand-written tapes that predate this generator. Craft beats generation; never clobber them. */
const HAND_WRITTEN = new Set(
  ["bundle", "checkpoint", "diff", "doctor", "new", "paths", "ports",
   "redact", "seed", "sessions", "tokens", "tree"],
  // "unpack" removed 2026-08-31 with demo/tapes/unpack.tape and the command itself —
  // see docs/specs/move-5-delete-unpack.md.
);

/**
 * Does this command actually WORK, against the same fixture the tape will use?
 *
 * The alternative is guessing, and guessing produced four tapes referencing files the fixture
 * does not contain (`src/a.ts`, a `shot.png` that was never there). A tape is only written for a
 * command that has just been executed for real and exited clean — the same rule demo/verify.sh
 * applies before filming, moved one step earlier so a broken tape is never written at all.
 *
 * Returns null when it works, or the reason it does not.
 */
function runs(command) {
  const dir = mkdtempSync(resolve(tmpdir(), "chute-short-"));
  try {
    execFileSync(resolve(HERE, "fixtures/make.sh"), [dir], { stdio: "ignore" });
    execFileSync("bash", ["-c", command], {
      cwd: dir,
      encoding: "utf8",
      stdio: ["ignore", "pipe", "pipe"],
      env: { ...process.env, PATH: `${resolve(HERE, "../.build/release")}:${process.env.PATH}` },
      // A command that has not returned in 15s cannot be the subject of a 6-second tape, and it
      // will hang this script rather than fail it. `chute latest --quicklook` opens a QuickLook
      // window and waits — which is exactly the class of thing that must not be filmed anyway,
      // so the timeout doubles as the policy rather than needing a separate list entry.
      timeout: 15_000,
      killSignal: "SIGKILL",
    });
    return null;
  } catch (e) {
    if (e.signal === "SIGKILL") return "it does not return — it opens a window or waits for input";
    const err = (e.stderr || e.stdout || String(e.message)).split("\n")
      .filter(Boolean).slice(-1)[0] ?? "failed";
    return err.replace(/^chute: /, "");
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
}

/** Which existing tape already covers a case, if any. */
function existingTape(command) {
  const verb = command.replace(/^chute /, "").split(" ")[0];
  return HAND_WRITTEN.has(verb) ? verb : null;
}

// VHS has no escape character inside a quoted string: `Type "chute note \\"x\\""` is a parse
// error, not an escaped quote, and the generator emitted exactly that — so `make demos` died on
// the one case whose command contains quotes, after re-recording the sixteen before it. VHS does
// accept all three quote characters, so the fix is to CHOOSE one the string does not contain
// rather than to escape anything. If a command ever contains all three, say so loudly here
// instead of writing a tape that cannot parse.
const vhsString = (s) => {
  for (const q of ['"', "'", "`"]) if (!s.includes(q)) return q + s + q;
  throw new Error(`cannot quote for VHS, the command uses all three quote characters: ${s}`);
};

const tape = (c) => `# ${c.pain}
#
# GENERATED from site/src/lib/cases.ts by demo/gen-shorts.mjs — do not edit by hand.
# The command below is the same string the page prints for this case. Change it there.
Source common.tape
Source setup.tape
Output out/${c.slug}.gif
Set Height 380

Sleep 600ms
Type ${vhsString(c.command)}
Enter
Sleep 2.5s
Sleep 1s
`;

let written = 0, reused = 0, skipped = [];
for (const c of FREE) {
  const verb = c.command.replace(/^chute /, "").split(" ")[0];
  if (UNFILMABLE[verb]) { skipped.push([c.slug, UNFILMABLE[verb]]); continue; }
  if (NEEDS_SETUP[verb]) { skipped.push([c.slug, NEEDS_SETUP[verb]]); continue; }
  const existing = existingTape(c.command);
  if (existing) {
    reused++;
    console.log(`  reuse  ${c.slug.padEnd(38)} → tapes/${existing}.tape (hand-written)`);
    continue;
  }
  const why = runs(c.command);
  if (why) {
    skipped.push([c.slug, `the command does not run in the fixture — ${why}`]);
    continue;
  }
  const path = resolve(TAPES, `${c.slug}.tape`);
  if (WRITE) writeFileSync(path, tape(c));
  written++;
  console.log(`  ${WRITE ? "write" : "would"}  ${c.slug.padEnd(38)} → ${c.command}`);
}

console.log(`\n  ${written} generated, ${reused} already hand-written, ${skipped.length} not filmable:`);
for (const [slug, why] of skipped) console.log(`    ${slug.padEnd(38)} ${why}`);
if (!WRITE) console.log("\n  (report only — pass --write to create them)");
