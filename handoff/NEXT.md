# HANDOFF — Chute: session switcher + onboarding — 2026-08-26

STATE: `feat/session-switcher` @ `1d4cbcf` · pushed (local == origin) · build green
       (`swift build -c release` → `Build complete!`) · unit 205/205 (`swift run chutetests`)
       · e2e 39/39 (`./Scripts/smoke.sh`) · `main` still at `e02b78c`, NOT merged

## ONE-LINE GOAL
A macOS utility that turns a Finder selection into agent-ready context and tells you which of your
running AI agents is waiting for you.

---

## MODEL ROUTING — binding for this project

| Role | Model | Scope |
|---|---|---|
| **Design, audit, code review, SDLC correction** | **Opus** | Every spec and plan. Every task review and re-review. Every ruling on a conflict. Anything touching `~/.claude/settings.json`, entitlements, or signing. |
| **Build from a written spec** | **Sonnet** | Implementation where the plan carries the code and the task needs judgment: parsers, state logic, AppKit, anything with error paths. |
| **Mechanical transcription** | **Haiku** | Single-file, fully-specified work with no design decisions: a pure function with given constants, script edits, doc updates. |

Rules that made this work, and must not be dropped:
1. **One agent per file.** Never two agents in one file. Parallel only on provably disjoint files.
2. **Every implementer gets a perturbation step**: break your new guard, prove the suite goes RED,
   restore it. A green suite nobody saw fail is not evidence.
3. **Every task gets an independent review; every fix round gets a scoped re-review.**
   Two of this session's defects were introduced BY fixes to earlier defects.
4. **Reviews get an adversarial question, not "review this."** Ask what specifically could be
   wrong — clock skew, sandbox, threading, a failure atlas. Generic reviews found generic things.
5. **The controller never fixes findings itself.** It rules, ledgers the ruling, and re-dispatches.

### Security standard for any task touching the user's config
`~/.claude/settings.json` holds 12 configured hook events driving the founder's whole workflow.
Any code touching it: **back up first · parse never template · append only · idempotent ·
validate before replacing · fully reversible · never run install/uninstall during verification
(temp fixtures only).** Enforced in `/Users/sxope/Documents/2026/Development/37.chute/Sources/ChuteCore/HookInstaller.swift`.

---

## DONE (verified — each proved by a command that was RUN)

- **Engine, 6 tasks** — proved by `swift run chutetests` → `✅ 205 assertions passed`
- **End-to-end** — proved by `./Scripts/smoke.sh` → `smoke: 39 passed, 0 failed`
- **`chute sessions` lists real windows** — proved by `./.build/release/chute sessions` →
  `→ 9 session(s), 0 need you` with 7 agents and 2 shells across 4 projects
- **`chute focus 1` works** — proved by the frontmost process flipping Docker Desktop → Terminal
- **`chute doctor` diagnoses honestly** — proved by `chute doctor` → `→ 4 of 8 checks failed`
  ending `— end-to-end test skipped: fix the above first`, exit 1
- **Menu-bar switcher installed and running** — `pgrep -x ChuteApp` returns a pid; 996K bundle
- **A sandboxed FinderSync appex works ad-hoc signed, no Xcode, no $99** — proved by a throwaway
  spike: registered under `com.apple.FinderSync` and enabled via `pluginkit -e use`. Probe deleted.

## IN FLIGHT
- **Task 7 review** (`chute sessions|focus|hooks`) — dispatched, not returned. Code is committed on
  `worktree-agent-ae0cb4e0a35cb7b80` @ `200fd11`, **NOT merged**. Merge only after the review is clean.
  What breaks if ignored: `chute sessions` is absent from the merged branch despite working.

## NEXT
1. `git merge worktree-agent-ae0cb4e0a35cb7b80 --no-edit`
   — after Task 7's review is clean. expect: `Sources/chute/Commands/SessionCommands.swift` created
2. `cd /Users/sxope/Documents/2026/Development/37.chute && swift run chutetests && ./Scripts/smoke.sh`
   expect: `✅ 205 assertions passed` and `smoke: 39 passed, 0 failed`
3. **Fix the phantom badge** (see TRAPS) — `updateBadgeFromHooks()` at
   `/Users/sxope/Documents/2026/Development/37.chute/Sources/ChuteApp/main.swift:194` counts hook
   files without intersecting live ttys. Sonnet. This is the headline feature; a badge the user
   learns to distrust is worse than no badge.
4. **Task 9** — smoke coverage for `sessions`/`doctor`/`hooks`, install wiring, README. Haiku.
5. **Offer `chute hooks install`** — run it against a COPY first, diff it, show the founder, then ask.
   Until then every session reads `working` and the badge stays dark.
6. **FinderSync** — `/Users/sxope/Documents/2026/Development/37.chute/docs/superpowers/plans/2026-08-26-findersync-context-menu.md`.
   Task 2 carries a hard STOP: prove a sandboxed appex can reach the app BEFORE writing menu code.
7. `git checkout main && git merge feat/session-switcher` once 3–4 are done.

---

## DECISIONS (do not re-litigate)

- **FinderSync extension, not Services or Automator Quick Actions.** Both were built, both
  registered with macOS, neither ever appeared. `pbs` registers app `NSServices` into a submenu
  Finder buries; `FinderActive` never lists synthesised `.workflow` bundles. Evidence and the
  rejected-mechanisms table: `/Users/sxope/Documents/2026/Development/37.chute/docs/08-MACOS-COMPATIBILITY.md`.
- **No Xcode, no $99 yet.** Proved sufficient for local development by spike. The Developer ID is
  needed before anyone ELSE can install, not before the menu works here.
- **No XCTest.** It ships with Xcode. The suite is an executable with an assert harness:
  `swift run chutetests`. `swift test` does not work on this machine and never will without Xcode.
- **Zero third-party dependencies.** Never add `.package(` to Package.swift.
- **Zero telemetry.** It is a positioning asset with this audience, not just an ethical stance.
  See `/Users/sxope/Documents/2026/Development/37.chute/docs/09-GTM-DECISIONS.md` #8.
- **Beachhead is multi-agent solo devs on macOS**, not "AI builders". Riskiest assumption is A1:
  *a stranger can install this and see the menu* — the only one with evidence AGAINST it.
- **Onboarding detects and verifies; it never instructs.** On macOS 15.0–15.1 Apple REMOVED the
  Extensions settings pane, so "tick the box in System Settings" pointed at a screen that did not
  exist for two OS releases.
- **`.sortedKeys` in HookInstaller is deliberate.** Removing it does NOT preserve the user's key
  order — Swift dictionaries are unordered and hash seeds are randomised, so output order changes
  every run. The real choice is stable vs random. Verified over 5 runs: 5/5 red without it.

---

## TRAPS (each cost real time today)

- **`pgrep -x Terminal` NEVER matches Terminal.app.** macOS reports a bundled app's `comm` as its
  full executable path. → Use `ps -Ao comm` and a path-fragment match. `isAppRunning` at
  `/Users/sxope/Documents/2026/Development/37.chute/Sources/ChuteCore/TerminalAppAdapter.swift:63`.
- **An appex registers when its HOST APP IS LAUNCHED**, not on `pluginkit -a`. Measured:
  `pluginkit -a` → not registered; `lsregister -f` → not registered; `open <app>` → registered.
- **`NSExtensionMain()` is not callable from Swift.** Build the appex with
  `-Xlinker -e -Xlinker _NSExtensionMain` and NO `main.swift`.
- **App extensions are SANDBOXED.** The "appex spawns `chute`" design is UNPROVEN — a child
  inherits the sandbox. Google Drive's extension signals its host app instead. Gated at Task 2.
- **APFS is case-INSENSITIVE.** `Contents/MacOS/Chute` and `.../chute` are the same file; the CLI
  silently overwrote the app binary. The app executable is named `ChuteApp` for this reason.
- **`git stash create` EXCLUDES untracked files** — exactly what an agent creates. `checkpoint`
  uses a private `GIT_INDEX_FILE` + `add -A` + `write-tree` + `commit-tree` instead.
- **`ps -o tty=` prints `??`, not empty**, when there is no controlling terminal. A guard on
  emptiness never fires. Whitelist `[a-zA-Z0-9]` instead.
- **Worktrees branch from the REPO BASE, not the working branch.** Every parallel dispatch must
  start with `git merge feat/session-switcher --no-edit` or the agent builds against stale code.
- **Worktrees contain only TRACKED files.** `.superpowers/` scratch does not exist inside them —
  point agents at the COMMITTED plan file and a task heading, never at a generated brief.
- **`git log origin/<branch>..HEAD` returns 0 when the branch was never pushed.** The error is
  suppressed and silence reads as success. Verify with `git ls-remote --heads origin <branch>`.
- **The installed CLI is a COPY inside the app bundle.** After any Swift change run
  `./Scripts/build-app.sh && ./Scripts/install.sh`, or `~/.local/bin/chute` stays stale.
- **PHANTOM BADGE (open bug).** `updateBadgeFromHooks()` counts hook files without intersecting
  live ttys, so a closed window's `waiting` record inflates the badge for up to 6 hours.

---

## OPEN QUESTIONS FOR THE HUMAN
1. **Install the Claude Code hooks?** Until then every session reads `working` and the badge stays
   dark. It appends to `~/.claude/settings.json`, backs up first, and reverses with one command —
   but it is your config. Recommend: run against a copy, diff it, then decide.
2. **Buy the $99 Apple Developer ID?** Not needed for local use. Needed before anyone else can
   install without a Gatekeeper warning, and before Product Hunt is worth doing.
3. **Price: $9 or $19?** `docs/09-GTM-DECISIONS.md` argues $9 for volume; $19 is defensible on a
   90-min/day saving once signed and auto-updating.
4. **Merge to `main` now or after the FinderSync menu works?** `main` is still at `e02b78c`.

---

## SCOREBOARD (why the process is shaped this way)
**19 defects caught. 17 originated in the plan or the controller's instructions. 0 were agent
implementation errors.** Two were introduced BY fixes to earlier defects. Two of the plan's tests
were placebos — present, passing, asserting nothing. The unit tests found none of the important
bugs; independent adversarial review and agents refusing to fake a red run found all of them.
