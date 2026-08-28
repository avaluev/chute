# SPEC — Moves 0 + 2: stop the false alarm, and make "working" mean working

Repo root: `/Users/sxope/Documents/2026/Development/37.chute`
Owner: ONE agent — these five files share a single new concept (`severity`) and cannot be split.

Files you own:
- `/Users/sxope/Documents/2026/Development/37.chute/Sources/ChuteCore/Diagnostics.swift`
- `/Users/sxope/Documents/2026/Development/37.chute/Sources/ChuteCore/StatusMenu.swift`
- `/Users/sxope/Documents/2026/Development/37.chute/Sources/ChuteApp/FirstRunWindow.swift`
- `/Users/sxope/Documents/2026/Development/37.chute/Sources/ChuteApp/Onboarding.swift`
- `/Users/sxope/Documents/2026/Development/37.chute/Sources/ChuteApp/main.swift`
- `/Users/sxope/Documents/2026/Development/37.chute/Sources/chutetests/DiagnosticsSuite.swift`
- `/Users/sxope/Documents/2026/Development/37.chute/Sources/chutetests/StatusMenuSuite.swift`

Findings go to `/Users/sxope/Documents/2026/Development/37.chute/docs/specs/move-0-2-FINDINGS.md`.

---

## The shared root cause

`Check` (`Diagnostics.swift:6-15`) has **no severity field**. Every consumer therefore renders
"everything that is not `passed`", and cannot tell a blocker from a note. That single gap produces
both of today's false signals:

- `FirstRunWindow.swift:88-91` titles a clean, correct, app-only install
  **"2 things need your permission"** — over `cli` (Homebrew, which
  `Scripts/install.sh:31-34` says the app does not need) and `terminal`, whose own fix text at
  `Diagnostics.swift:80` reads *"Informational only — nothing is broken."* Neither is a permission.
  It offers a **Fix These** button that repairs neither.
- `chute doctor` prints **"all 9 checks passed"** on a machine whose badge is permanently dark,
  because there is deliberately no hooks check at all (`Diagnostics.swift:81-83`).

This is the same failure mode the repo spent a session on: **a plausible signal answering a
different question than the one asked.** Shape, not substance.

---

## Part 1 — `severity` on `Check`

Add `public enum Severity { case blocker, note }` and a `severity` field, defaulting to `.blocker`
so every existing check keeps its meaning without being touched.

Mark `.note`: **`cli`** and **`terminal`**. Nothing else changes severity.

Then:
- **`FirstRunWindow.showIfNeeded()` (`:22-29`) opens the window only when a `.blocker` fails.** A
  correct install must show NOTHING.
- When it does open, the title counts blockers only, and notes — if rendered at all — appear
  without the alarm wording. Your call whether a note renders; justify it in FINDINGS.
- **`chute doctor`'s exit code must not change for a failing `.note`.** This is load-bearing:
  `DoctorCommand.swift` exits non-zero on any failure today, and a note that flips CI red would
  make the whole change unshippable. A failing note prints, and exits 0.
  NOTE: another agent may be editing `DoctorCommand.swift` in the wave before yours. Check `git
  status` first; if it is dirty, coordinate by reporting the needed change in FINDINGS rather than
  editing it. If the tree is clean, you may make this one exit-code change there.

## Part 2 — a `hooks` check, severity `.note`

The principle at `Diagnostics.swift:81-83` — never nudge anyone to edit `~/.claude/settings.json` —
is RIGHT and STAYS. **Reporting a state is not nudging.** Read-only; write nothing.

Add a check that reads `HookInstaller.status(settingsPath:)`
(`/Users/sxope/Documents/2026/Development/37.chute/Sources/ChuteCore/HookInstaller.swift:133` area).
Fix text, near-verbatim: *"agent status hooks are not wired — the badge will stay dark.
`chute hooks snippet` prints what to paste; Chute never edits that file itself."*

`applyFixes` must have NO case for it — hooks deliberately have no `--fix`.

`DiagnosticsSuite.swift` asserts `Diagnostics.all.count == 9`. That becomes 10. The assertion's
comment explains WHY nine — rewrite the comment to explain why ten, do not just bump the number.

## Part 3 — onboarding has no way back

1. `Onboarding.swift:33-37` sets `UserDefaults "onboarded" = true` on line 35, **before** `show()`
   on line 36. Quit mid-wizard and it never returns; the only escape is
   `defaults delete dev.valuev.chute`, documented in a code comment. Move the write into the
   Finish branch of `Handler.next()` (`:140-145`). **Skip on the last beat still counts as done**
   — do not create a wizard the user cannot dismiss.
2. `main.swift:198` — `@objc func openSetup() { FirstRunWindow.show() }` exists and is referenced
   NOWHERE in the repo. Dead code that is exactly the missing way back. Wire it: a new
   `StatusMenu.Command` case, a `Setup…` row in `StatusMenu.standardItems` (`:203-238`), and the
   matching arm in `main.swift`'s `selector(for:)`.
3. `main.swift:46,51` runs `FirstRunWindow.showIfNeeded()` and `Onboard.showIfFirstRun()`
   unconditionally — two windows both titled "Chute" can stack on first launch with the teaching
   one underneath. Show the wizard OR the repair window, never both.

## Part 4 — two menu rows that explain a silent state

`StatusMenu` is pure data in ChuteCore precisely so a headless test can read it. Both rows go in
the MODEL, and are asserted in `StatusMenuSuite.swift` (see `titles()`/`find()` helpers at `:18-23`).

1. **The badge cannot work and nothing says so.** `updateBadgeFromHooks()` (`main.swift:338-343`)
   reports `0` when `HookState.readAll()` is empty — "never wired" and "nothing needs you" are the
   same picture. When there are live sessions but **zero hook records have ever existed**, emit ONE
   row: `Agent status needs a hook — Copy the Snippet`, payload `HookInstaller.manualSnippet()`.
   Zero records ever is not the same as zero CURRENT records — get that distinction right.
2. **An expired trial makes Recent Copies and Local Servers vanish silently.**
   `StatusMenu.swift:207` drops both when `!unlocked`. To the user that is indistinguishable from
   "empty" — the same false signal as everything else in this spec. When locked, emit one row
   saying the section is behind the licence. Do NOT weaken the gate; only explain it.

---

## Constraints

- Be lazy: `severity` is one enum and one field with a default. Do NOT introduce a severity
  hierarchy, a config, a protocol, or a `Vocabulary` table. Every row here is a handful of lines.
- Never write to `~/.claude/settings.json`. Read-only, always.
- Do NOT edit `Sources/chutetests/CoreSuites.swift` or any `Sources/chute/Commands/*` file except
  the single `DoctorCommand.swift` exit-code line described above, and only if the tree is clean.

## Verify
```bash
swift build -c release && swift run -c release chutetests
cd /Users/sxope/Documents/2026/Development/37.chute && ./Scripts/smoke.sh
cd /Users/sxope/Documents/2026/Development/37.chute && CHUTE_HEADLESS=1 ./Scripts/smoke.sh
```
Baselines: **962 unit · 158 smoke · 130 headless** (the parent will give you the real current
numbers at dispatch — beat those, and report the REAL ones you got).

**Perturb every new guard to RED before believing it.** Set `cli` back to `.blocker` and watch the
clean-install assertion fail; delete the hooks row and watch the menu assertion fail. Record the
actual failing counts. A guard that stays green when the bug returns is not a guard.

Do NOT commit. Leave the tree dirty; the parent commits.
