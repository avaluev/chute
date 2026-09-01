# Test plan — every menu item, every JTBD

> Written 2026-09-02. The executable half is `Scripts/fixtures.sh` and `Scripts/acceptance.sh`;
> this document is the design behind them and the procedure for an unattended run.
> **A case that is only in this file is not a test.** Every ID below exists in the script.

## Why this exists

Two bugs reached the founder's own hands in two days, both in shipped menu items, both invisible
to a green suite:

- **Copy Folder Tree** returned the tree of whichever item Finder sorted first. `__pycache__`
  sorts first in a Python project.
- **Copy Folder Tree ▸ All Levels** hung forever on any repo containing a symlink loop.

Neither was exotic. Both were found in minutes once something pointed the actions at a directory
that looked like a real developer's disk instead of `src/a.ts`.

---

## 1. The surface under test

Nine actions in five rows. Every one is a `chute` invocation, and the templates are read from
`chute finder-actions --json` rather than copied — so an action added without cases fails the run
(cases `COV-*`).

| Row | Action id | Scope | Command it runs |
|---|---|---|---|
| Copy Full Paths | `copy-paths` | selection | `paths {files}` |
| Copy Files as Context | `bundle-xml` | selection | `bundle {files}` |
| Copy Folder Tree ▸ 2 Levels | `tree-2` | folder | `tree {dir} --depth 2` |
| ▸ 4 Levels | `tree-4` | folder | `tree {dir} --depth 4` |
| ▸ All Levels | `tree-all` | folder | `tree {dir} --depth 99` |
| Add to Context Basket | `basket-add` | selection | `basket add {files}` |
| New File ▸ Empty Markdown | `new-markdown` | folder | `new --blank --rename --dir {dir}` |
| ▸ Markdown from Clipboard | `new-markdown-clipboard` | folder | `new --naming underscore --ext md --rename --dir {dir}` |
| ▸ Image from Clipboard | `paste-image` | folder | `paste-image --dir {dir}` |

**What the harness cannot reach: the click.** Which folder a `.folder` action applies to, and
whether an empty selection is refused, is `ChuteCore.FinderTarget` — covered by the unit suite,
extracted precisely because it was unreachable when it was wrong.

## 2. How the cases were designed

Not by intuition. Five techniques, applied per action:

- **Equivalence partitioning.** Inputs fall into classes that behave alike — a readable text file,
  a binary, an unreadable file, a missing path, a directory. One representative each; more is
  waste.
- **Boundary value analysis.** Depth 2 must include level 2 and exclude level 3. The truncation
  cap must pass at the limit and truncate at limit+1. Zero files, one file, 500 files.
- **Decision tables.** `basket add` crosses {exists, missing} × {already in basket, not} — four
  outcomes, and three of them used to report the fourth.
- **State transition.** The basket is the only stateful surface: empty → holding → holding-a-
  missing-file → empty. The interesting edge is the file vanishing *between* `add` and `copy`.
- **Error guessing, informed by the two real bugs.** Both came from the filesystem being weirder
  than the fixture. Hence `Scripts/fixtures.sh`.

## 3. The fixture tree

`./Scripts/fixtures.sh [dir]` — idempotent, refuses any path not under a temp dir or named
`chute-fixtures`, because its job is `rm -rf`.

| Group | What is in it | What it is for |
|---|---|---|
| `names/` | space · `"` · `'` · `\` · **newline** · leading `-` · `$(whoami)` · backtick · `;` · `*` · `?` · `[` · `\|` · `&` · tab · emoji · Cyrillic · CJK · RTL · **NFC vs NFD** · `...` · trailing space · 250 bytes | Every escaping path: AppleScript literals, shell quoting, XML attributes, argv |
| `content/` | zero-byte · no trailing newline · CRLF · **a literal `</file>`** · `"` `&` `<` · binary · NUL-in-text · invalid UTF-8 · 10 MB · one 100k-char line | The bundle wrapper's own sentinel, the binary rule, size |
| `structure/` | empty dir · 30 levels · 500 files | Depth boundaries, breadth, performance |
| `links/` | file · dir · broken · **real loop** · hardlink · one pointing at `/etc` | The hang, and leaving the tree |
| `repo/` | node_modules · __pycache__ · venv · .git · build · dist · **.github** · .env · .DS_Store | Junk exclusion, and the one dot-directory that is kept |
| `permissions/` | unreadable file · unreadable directory | Refusals that must not read as emptiness |

**One fixture was wrong on the first attempt and passed anyway.** `ln -s ../links` from inside
`real/` resolves to `links/links`, which does not exist — a broken link masquerading as a loop
test. It was caught by checking `readlink -f`, not by the test going green. **Verify a negative
fixture actually reproduces the negative.**

## 4. The cases

80, all in `Scripts/acceptance.sh`. The run reports 81 — the extra one is the script checking
that this very number is still right. Grouped by action; every one is positive (P), negative (N),
boundary (B) or corner (C).

### Copy Full Paths — `P-01 … P-12`
Two ordinary files (P) · absolute output (P) · space, double quote, **newline**, leading dash,
`$(whoami)`, emoji in the filename (C) · no arguments → the working directory, by design (B) ·
a missing path (N) · relative format drops the prefix (B) · 500 paths under 2 s (perf).

### Copy Files as Context — `B-01 … B-15`
A folder expands (P) · each file tagged with its path (P) · node_modules, `__pycache__`, `.git`
excluded (P) · **a binary-only selection fails rather than emitting rubbish** (N) · a literal
`</file>` in the content is neutralised (C) · zero-byte file (B) · bad UTF-8 does not sink the
readable files, and alone is refused (C) · unreadable file reported (N) · a quote in a path is
XML-escaped (C) · an empty folder says so (N) · 10 MB under 3 s and 500 files under 5 s (perf) ·
a symlink loop does not hang the bundler (C).

### Copy Folder Tree — `T-01 … T-15`
Root names itself (P) · junk excluded, `.github` kept (P) · **depth 2 stops at 2, depth 4 reaches
4 and stops, depth 99 reaches the bottom** (B) · **a symlink loop terminates under 5 s, is named
rather than followed, and the tree never leaves the folder** (C — the 2026-09-02 hang) · empty
folder (B) · a file is refused (N) · a missing folder is refused (N) · an unreadable subdirectory
does not abort the walk (N) · 500 entries under 2 s (perf).

### Add to Context Basket — `K-01 … K-09`
Two files in and listed back (P) · a duplicate does not claim to have added one (C) · **a missing
file fails and names the real cause** (N — the 2026-09-02 bug) · a partial failure names what did
not go in (C) · a newline filename does not corrupt the store (C) · copy as context yields the
contents (P) · clear empties it (P) · copying an empty basket is refused (N) · **a file deleted
after adding is marked missing, and copying an all-missing basket is refused** (state transition).

### New File — `N-01 … N-08`
Created (P) · a second does not overwrite the first (C) · both exist (B) · a missing folder (N) ·
**an unwritable folder is refused, not reported as created** (N) · from the clipboard, named from
its heading (P) · **an empty clipboard is refused rather than making an empty file** (N).

### Image from Clipboard — `I-01 … I-06`
Text on the clipboard is refused with a reason (N) · a missing folder is refused (N) · **a real
PNG is saved** (P) · **it does not wait 90 s for a rename that cannot happen headlessly** (C — the
2026-09-02 block) · exactly one PNG lands (B) · and it is a real PNG rather than renamed bytes (C).

The positive cases generate a 4×4 PNG and put it on the clipboard with `osascript`. That needs a
logged-in session, so they are attempted and **skipped with a message** where it fails, never
passed quietly.

## 5. Performance budgets

Budgets, not measurements — they fail the run when crossed. Current readings on this machine, for
the record only: symlink loop 76 ms (was: never returned), 500-entry tree 100 ms.

| Case | Operation | Budget |
|---|---|---|
| P-12 | 500 paths | 2 s |
| B-13 | bundle a 10 MB file | 3 s |
| B-14 | bundle 500 files | 5 s |
| T-08 | tree across a symlink loop | 5 s |
| T-15 | tree of 500 entries | 2 s |

**Do not tighten a budget to the current reading.** A budget that fails on a loaded machine is a
gate people learn to re-run rather than read — the mistake `check-metrics` explicitly refuses to
make.

## 6. Definition of Done

A change to any menu item is done when **all six are true and were observed, not assumed**:

1. `swift build -c release && swift run -c release chutetests` — green, and the count went up if
   behaviour changed.
2. `CHUTE_HEADLESS=1 ./Scripts/smoke.sh` — green, tally read rather than exit code.
3. `./Scripts/acceptance.sh` — green, and the action has a case for the new behaviour.
4. `./Scripts/check-untested-logic.sh` — the ratchet did not grow.
5. **Every new guard was perturbed to red and restored.** A guard never seen failing is a hope.
6. `./Scripts/build-app.sh` — the entitlements and the size claim still assert.

And for anything user-visible: `marketing/06-FACT-SHEET.md` §Verification re-derived, never
retyped.

## 7. JTBD coverage

The nineteen jobs in `site/src/lib/cases.ts` are what the site sells. Which are covered here:

| Surface | Jobs | Covered by |
|---|---|---|
| Finder, paid | 5 | `P-*`, `B-*`, `T-*`, `K-*`, `N-*` — all five rows |
| Menu bar, paid | 2 | `whats-on-port-3000` by smoke; `which-agent-is-waiting-for-you` **not covered** — it needs live terminal sessions |
| Free CLI | 12 | `Scripts/smoke.sh` |

**One honest gap left**: the menu bar's session list, which needs live terminal sessions. It is
also the surface still carrying `savedMinutes: null` in the ledger. The `paste-image` gap was
closed on 2026-09-02 — and closing it immediately found a 90-second headless block, which is the
argument for closing gaps rather than documenting them.

## 8. Running it unattended

Safe with nobody at the machine: it never touches the real basket (`CHUTE_BUFFER_DIR`), never
reaches for Finder (`CHUTE_HEADLESS=1`), restores the clipboard on exit, and writes only inside
its own temp directories.

```bash
swift build -c release \
  && swift run -c release chutetests \
  && CHUTE_HEADLESS=1 ./Scripts/smoke.sh \
  && ./Scripts/acceptance.sh --perf \
  && ./Scripts/check-untested-logic.sh \
  && ./Scripts/check-metrics.sh
```

`check-metrics` goes red about one run in three under load and green on a quiet machine — that is
documented and deliberate; re-run it alone rather than widening the bound.

**What still needs a human at the keyboard**, and cannot be automated away:

- The full `./Scripts/smoke.sh` (not headless) drives real Finder actions and owns the clipboard
  for ~30 s.
- A real right-click on each of the nine rows, once, after any change to the extension.
- `./demo/gui/by-hand.sh` — the stopwatch that turns every published figure from an estimate into
  a measurement.
