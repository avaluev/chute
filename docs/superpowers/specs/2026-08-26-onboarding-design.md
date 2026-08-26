# Design — Onboarding and first-run

**Date:** 2026-08-26 · **Status:** awaiting review · **Subsystem:** 3 of 3
**Priority: ahead of Tasks 7–9.** This tests assumption A1 in `docs/09-GTM-DECISIONS.md` — the only
assumption currently failing.

## Problem

Chute's engine is 116 verified assertions strong and its core feature has never once appeared for
its own author. Three integration attempts registered correctly with macOS and produced nothing in
Finder. If the founder — holding the source, a compiler and an agent — cannot reach the product,
a stranger with a DMG has worse odds.

**A product whose core feature is invisible on arrival converts at zero, regardless of engine quality.**

### Why instructions cannot be the answer

From `docs/08-MACOS-COMPATIBILITY.md`: on **macOS 15.0 and 15.1 Apple removed the Extensions
configuration UI entirely.** For two full OS releases, "tick the box in System Settings →
Extensions" pointed at a screen that did not exist. Any onboarding built on told steps is already
broken for a slice of users and will break again.

**Therefore: never instruct. Detect, verify, and where possible repair.**

## Decision

A single diagnostic engine with two faces:

- `chute doctor` — CLI, scriptable, the source of truth
- **First-run window** — the same checks rendered as a live checklist, shown once on first launch
  and reachable afterwards from the menu bar

Both call the same `Diagnostics` type in `ChuteCore`. There is no second implementation, so the
window can never disagree with the CLI.

## The checks

Every check answers three things: **is it satisfied, why does it matter, and what fixes it.**
A check that cannot state its own fix is not allowed to ship.

| # | Check | How it is verified (not assumed) | Auto-fix |
|---|---|---|---|
| 1 | macOS ≥ 13 | `ProcessInfo.operatingSystemVersion` | none — explain and stop |
| 2 | App is in `/Applications` or `~/Applications` | bundle path prefix | offer to move |
| 3 | CLI reachable | `Bundle.main` + PATH probe | symlink into `~/.local/bin` |
| 4 | Finder extension registered | `pluginkit -m -p com.apple.FinderSync` contains our id | `pluginkit -a` |
| 5 | Finder extension **enabled** | `pluginkit -mA` flag column shows `+` not `-` | `pluginkit -e use -i <id>`, then verify |
| 6 | Automation permission for Terminal | run a trivial `osascript` probe and read the error | trigger the prompt, deep-link on denial |
| 7 | A terminal is running | `ps -Ao comm` (never `pgrep` — see compatibility doc) | none — informational |
| 8 | Claude Code hooks installed | `HookInstaller.status` | `chute hooks install`, backed up |
| 9 | **End-to-end proof** | actually run `chute paths` on a temp file and read the clipboard back | — |

**Check 9 is the one that matters.** Checks 1–8 verify components; check 9 verifies the product.
A green run of 1–8 with a failing 9 is precisely the state this project has been in all day.

## Output contract

```
$ chute doctor
✓ macOS 14.6.1                        (need 13+)
✓ App location                        ~/Applications/Chute.app
✓ CLI on PATH                         ~/.local/bin/chute
✓ Finder extension registered         dev.valuev.chute.finder
✗ Finder extension NOT enabled        macOS has it switched off
    Why: the right-click menu cannot appear until macOS enables the extension.
    Fix: chute doctor --fix          (or System Settings → Extensions → Finder)
✓ Automation permission               Terminal responds
✓ Terminal running                    8 windows
✗ Claude Code hooks not installed     the menu bar cannot show which agents are waiting
    Fix: chute hooks install         (appends only, backs up first, reversible)
— end-to-end test skipped: fix the above first

2 of 9 checks failed.
```

`--fix` applies every auto-fix, then **re-runs every check** and reports the new state. It never
claims success it has not re-verified — the failure mode this whole project has been fighting.

Exit codes: `0` all pass · `1` something failed · `2` an unfixable environment problem (macOS too old).

## First-run window

`LSUIElement` apps have no Dock icon, so a first run with no window is indistinguishable from a
crash. Shown once, keyed on a flag in `~/.chute/state.json`:

```
  Chute is almost ready
  ─────────────────────────────────────────
  ✓  Installed
  ✓  Command line tool
  ⏳ Finder menu            [ Enable ]
  ⏳ Agent status hooks     [ Install ]        Appends to your Claude Code
                                              settings. Backed up first.
                                              Reversible with one command.
  ─────────────────────────────────────────
  [ Fix everything ]              [ Skip ]
```

Rules:
- **No dead ends.** Every failing row carries a working button or a copyable command.
- **Live re-verification.** Buttons apply the fix and re-run the check; a row turns green only
  when the check passes again.
- **Consent is explicit for anything that writes.** The hooks row states what it touches, that it
  backs up, and that it is reversible — before the user presses anything.
- **Skip is always available** and never re-nags. The CLI works with zero permissions granted.
- On success the window shows the first win directly: *"Select files in Finder → right-click →
  Chute ▸ Copy Paths for Prompt"*, and closes for good.

## What this deliberately does not do

| Not doing | Why |
|---|---|
| A multi-screen tutorial | The product is a right-click. Anything longer than one screen is an admission it is too complex. |
| Telemetry on the funnel | Contradicts the zero-telemetry promise (`docs/09-GTM-DECISIONS.md` #8). ECP feedback is qualitative at n=20. |
| Auto-granting permissions | Impossible and hostile. macOS gates them for good reason. |
| Re-prompting after Skip | A nagging menu-bar app gets uninstalled. |

## Success criteria

| Metric | Target | Measured how |
|---|---|---|
| Time to first win | **< 60 s** from launch | Watched, with ECP users |
| Install → first successful command | > 80 % | ECP self-report |
| `chute doctor` correctly diagnoses a broken install | 100 % | Deliberately break each of the 9, confirm doctor names it |
| Dead-end states | **0** | Every failing check has a fix path — enforced by a test |

## Testing

**Pure and testable:** each check is a `Check` value with an id, a title, a `why`, and a
`fix` — the evaluation function is injected, so the whole matrix is exercised with stubs and no
system calls. Includes a test asserting **every** check defines a non-empty `why` and `fix`, which
mechanically forbids a dead end from ever being added.

**End-to-end:** `Scripts/smoke.sh` runs `chute doctor --json` and asserts the shape; and a
deliberate-breakage test unregisters the extension, confirms doctor reports exactly that, then
re-registers.

**Manual gate:** on a second Mac, cold — install, launch, and time to first win. **This is the
real test of assumption A1 and nothing else substitutes for it.**
