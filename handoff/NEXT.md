# HANDOFF — Chute v0.1 — 2026-08-26

STATE: main / v0.1.0 / pushed · build green (`swift build -c release`, 0 warnings)
       unit 52/52 (`swift run chutetests`) · smoke 39/39 (`./Scripts/smoke.sh`)

## ONE-LINE GOAL
A macOS utility that turns a Finder selection into agent-ready context and agent output back
into files — sellable, offline, zero telemetry.

## WHERE THE WORK LIVES
`/Users/sxope/Documents/2026/Development/37.chute` → `github.com/avaluev/chute` (private).
**NOT** `/Users/sxope/Documents/2026/Development/36.macai` — a parallel session owns that
directory (see TRAPS).

## DONE (verified)
- 24/24 JTBDs implemented as `chute` subcommands — proved by `./Scripts/smoke.sh` → `smoke: 39 passed, 0 failed`
- Pure engine in `/Users/sxope/Documents/2026/Development/37.chute/Sources/ChuteCore/` — proved by `swift run chutetests` → `✅ 52 assertions passed`
- Suite proven capable of failing: breaking the traversal guard in
  `/Users/sxope/Documents/2026/Development/37.chute/Sources/ChuteCore/MarkdownUnpack.swift:60`
  produced `❌ 1 failed, 51 passed`, then restored
- `Chute.app` built without Xcode (576 KB) and running — `pgrep -x ChuteApp` returns a pid
- Six Finder services registered — `pbs -dump_pboard` lists `Chute \U2013 Copy Paths for Prompt` et al.
- Docs: BR, FR-01…FR-24, NFR, JTBD ledger with time-saved math, CJM, DoD, backlog in `docs/`
- Marketing: positioning, landing copy, launch posts, pricing in `marketing/`

## NOT DONE — needs a human, 3 minutes
The right-click and the hotkey cannot be driven programmatically. Registration is verified;
the click itself is not. Run the **MANUAL GATE** below before telling anyone it works.

## MANUAL GATE
1. `cd /Users/sxope/Documents/2026/Development/37.chute && ./Scripts/install.sh`
2. Copy any markdown to the clipboard. Open Finder at `~/Desktop`.
3. Right-click a **folder** → *Services ▸ Chute – New File from Clipboard*.
   Expect: a correctly named `.md` file appears and is revealed.
4. Select 3 files → right-click → *Services ▸ Chute – Copy Paths for Prompt*, then paste.
   Expect: 3 clean absolute paths.
5. Press `⌥⌘N`. Expect: the action menu at the pointer.
   First run prompts for Automation permission — that is macOS asking if Chute may read the
   Finder selection. Approve it.
6. If entries are missing: System Settings → Keyboard → Keyboard Shortcuts → Services →
   Files and Folders → tick the Chute entries.

## DECISIONS (do not re-litigate)
- **No Xcode.** Only Command Line Tools are installed. A `FIFinderSync` extension needs Xcode
  (~10 GB), so v0.1 uses **NSServices declared by the app** instead of hand-built Automator
  `.workflow` plists — pure Swift, nothing to reverse-engineer, and it registered first try.
- **No XCTest.** It ships with Xcode, so `swift test` cannot run here. The suite is a plain
  executable with an assert harness (`Sources/chutetests/`). Consequence: `--enable-code-coverage`
  cannot produce a coverage number on this toolchain; the ≥80 % NFR is asserted by count
  (52 unit + 39 e2e over ~11 core modules), not machine-measured. CI on `macos-14` has Xcode
  and could measure it.
- **Zero dependencies.** Hand-rolled flag parsing beats swift-argument-parser for 25 subcommands.
- **The CLI is the product.** Every surface shells out to it, so the future FinderSync extension
  is a shell, not a rewrite.
- **Destructive commands preview by default.** `unpack` and `clean` require `--force`.
- Price direction $9 one-time via LemonSqueezy. No licensing code in v0.1 — deferred by you.

## TRAPS
- **A parallel session owns `/Users/sxope/Documents/2026/Development/36.macai`** (targets
  `MacAICore` / `MacAICLI`). This session overwrote its `Package.swift` at 17:28 and restored it;
  `swift build` there returned `Build complete!` with zero recompilation, proving the restore
  matched. Its `.gitignore` and `.github/workflows/ci.yml` may still be this session's versions.
  → Never write to `36.macai`.
- **APFS is case-insensitive.** `Contents/MacOS/Chute` and `Contents/MacOS/chute` are the same
  file; the CLI silently replaced the app binary and the app launched, printed CLI help and
  exited. The app executable is `ChuteApp` for this reason. → Never name a bundle executable a
  case variant of a sibling.
- **`git stash create` excludes untracked files.** It looked perfect for a non-destructive
  snapshot, but agent-created files are untracked — exactly what a checkpoint must capture.
  → Use a private `GIT_INDEX_FILE` + `git add -A` + `write-tree` + `commit-tree`
  (`Sources/chute/Commands/GitCommands.swift:20`).
- **Relative paths from a common ancestor collapse for a single file** (`a.ts`, not `src/a.ts`).
  → `ProjectRoot.of()` resolves git root → cwd → ancestor, in that order.
- The app is **ad-hoc signed only**. Gatekeeper will warn on any machine but this one.

## NEXT
1. Run the MANUAL GATE above. Nothing ships until it passes.
2. `cd /Users/sxope/Documents/2026/Development/37.chute && ./Scripts/smoke.sh` after any change.
3. Record the 20-second demo — shot list in `marketing/04-PRICING-AND-DEMO.md`.
4. Apple Developer Program ($99/yr) → notarize → then Product Hunt. Unsigned kills PH conversion.
5. v0.2 scope is in `docs/06-BACKLOG.md` — FinderSync extension needs Xcode first.

## OPEN QUESTIONS
- Price: $9 (volume, chosen) or $19 (defensible on a 90 min/day saving)?
- Public repo with an MIT core for GitHub reach, or stay fully private?
- Is `bundle` really the wedge? Instrument `bundle` vs `paths` usage once there are users.
