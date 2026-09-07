---
session: legacy
pid: 0
host: legacy
at: 2026-09-07T16:43:06Z
commit: legacy
kind: question
legacy-src: /Users/sxope/Documents/2026/Development/37.chute/handoff/archive/NEXT-2026-09-07-full.md:355
---
OPEN QUESTIONS FOR THE HUMAN
- The Basket: faster than typing three `@` paths, or delete it?
- The two session-switcher numbers, then cost the menu bar's flagship
  (`which-agent-is-waiting-for-you` is still `jtbd: 0`, `savedMinutes: null`, on what is now the
  only ICP-native surface in the product).
- Custom user actions: platform, or stay opinionated?
- **A Claude Code plugin/skill for `chute`** (`05-CONTENT-CALENDAR.md` §4a) — the highest-leverage
  distribution line in the campaign, and the same "is this a platform now?" question.
- **Should the assertion and line counts be gated MONOTONICALLY?** Both drifted unnoticed, and a
  suite silently dropped from `Sources/chutetests/main.swift` — 30 of them are registered by hand —
  would leave everything green with fewer assertions. An equality gate is wrong here: those numbers
  change on every commit, and a gate that fires on every rebuild is one people learn to ignore,
  which the build-stamp check already taught. A ratchet — may rise freely, may never fall — is the
  shape that fits, and it is the shape `check-untested-logic.sh` already implements. ~15 lines and
  a second baseline file. **Worth it, or is one ratchet enough?**
- **Is six hours the right staleness window for a hook record?** `StateResolver.staleAfterDefault`.
  At six hours, a session you left waiting overnight reads `Running — no status` in the morning
  rather than `waiting`, and drops off the badge — on the founder's machine right now that is three
  real "waiting for you" sessions shown as unknown. Raising it to 24 h recovers them; the risk it
  guards is a tty NUMBER being reused by a new tab, which would then wear the old session's state
  for a day. Comparing the record's `cwd` against the tab's project does NOT distinguish the two —
  checked on ttys001, where the shell had simply `cd`'d to the parent directory. **One line, and
  the founder's call.**
- **`chute help` and `README.md` have no gate between them.** The README generates the site's
  command table (`brand/gen-commands.mjs` reads the README, NOT the binary), and it had drifted to
  24 rows against 26 commands. `check-claims.mjs` already proves every command NAMED anywhere runs;
  the missing direction is every command that RUNS being named. ~5 lines, next to the
  `finder-actions --json` check that already invokes the binary. Third gate of the day — deliberately
  left for a decision rather than added on the spot.
- **Should `chute doctor` compare the PATH CLI's version against the app's?** The founder's Mac
  runs app 0.2.1 and Homebrew 0.2.0, and that mismatch is what made the apply command dangerous.
  The command no longer trusts PATH, so the danger is gone — but "your CLI is older than your app"
  is a real state doctor currently reports as `✓ Command line tool`. One check, and the fix line
  writes itself (`brew upgrade chute`).
- **The six `handoff/AUDIT-2026-08-28-*.md` are unreferenced and carry open markers.** Nothing
  links them and each has 1-5 unresolved-looking findings. They are either worth triaging into
  TRAPS and gates, or worth deleting on purpose — but not worth leaving as 99 KB of records nobody
  reads. Twenty minutes with `grep -n "\[ \]"` settles it.
