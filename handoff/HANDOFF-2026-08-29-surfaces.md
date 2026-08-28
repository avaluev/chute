# HANDOFF — the surfaces agree — 2026-08-29

STATE: `main` · `7f2f701 → a6b8a09` (7 commits) · tree clean · **pushed**
Counts live in ONE place: `marketing/06-FACT-SHEET.md` §Verification. Re-derived from the gates
this session, not copied forward.

```bash
swift build -c release && swift run -c release chutetests
cd /Users/sxope/Documents/2026/Development/37.chute && ./Scripts/smoke.sh
cd /Users/sxope/Documents/2026/Development/37.chute && CHUTE_HEADLESS=1 ./Scripts/smoke.sh
cd /Users/sxope/Documents/2026/Development/37.chute && ./demo/verify.sh
cd /Users/sxope/Documents/2026/Development/37.chute/site && npm run check:cases && npm run check:claims
```

## ONE-LINE GOAL

The three surfaces stop disagreeing with each other, and stop claiming things nobody checked.

---

## DONE (verified)

Moves 0–4 of `~/.claude/plans/chute-strategic-redesign.md`, plus the reported Recent Copies bug.

| Thing | Proved by |
|---|---|
| Recent Copies works | a copy files a row 3→4; a replay does not, 4→4; label reads `1 full path` |
| The app can say which build it is | `chute 0.2.0 · app build c1178d8 2026-08-28T18:31Z` |
| `unpack` takes a body-comment path | ` ```python ` + `# app/main.py` → `create app/main.py` |
| A shebang is not a path | `#!/bin/bash` used to offer `create !/bin/bash (19 bytes)` |
| `tokens` and `bundle` agree | perturbed: `~32 tokens` vs `~19 tokens`, red |
| Five destructive commands preview | throwaway listener survived `ports --kill`, died with `--force` |
| A note never blocks | forced `hooksWired=false`: hooks ✗, end-to-end ✓, **exit 0** |
| One job, one name | RED named it: `'sandbox-here' confirms with "clean"` |

**Three defects nobody had reported, found by checking rather than trusting a summary:**

- **`chute unpack` would create a directory called `!`.** Every caller strips a leading `#`, so
  `#!/bin/bash` reached `looksLikePath` as `!/bin/bash` — no space, full of slashes, passed.
  `pathFromContext` had the identical hole and had it before this session. Guard went in the
  shared predicate, `MarkdownUnpack.swift:73`.
- **Adding the hooks check would have skipped the end-to-end proof on nearly every install.**
  `blocked` meant "any prerequisite failed" and hooks are unwired by design on most machines. The
  probe needs no CLI, no terminal and no hook. `DoctorCommand.swift:67` now filters on `.blocker`.
- **CLI `buf all` filed its own output back into the buffer** — verbatim the defect `0d23f86`
  fixed in the menu bar's `bufferFlush` yesterday, in the sibling caller of the same shared
  function. Fixed at the fork: `Out.deliver(record:)`, `Args.swift:80`.

**Three callers left assuming the old behaviour of something gated this session** — one shape,
three instances, the third found by review: the GUI's **Fix These** button
(`FirstRunWindow.swift:196`), `install.sh:101`, and `uninstall.sh` — which previewed the legacy
hook removal and then deleted the only binary that could do it, while its own `2>/dev/null` hid
the reason. That line was ALSO calling `~/.local/bin/chute`, a path `install.sh` stopped creating
when Homebrew took over the CLI, so the legacy cleanup had been dead before the gate arrived.

---

## TRAPS — paid for once, do not pay again

- **A green suite says the SOURCE is right, never that the INSTALLED APP is.** `ContextBufferSuite`
  tests the Recent Copies regression against a temp directory and passed all evening while the
  running app carried the bug. The build stamp exists because of this; `chute doctor` prints it.
- **A test that recomputes the thing it is testing is not a test.** The `tokens`/`bundle`
  assertion was first written in `chutetests`, which links ChuteCore only — so it called the same
  ChuteCore functions and stayed green while `cmdTokens` was perturbed back to the broken sum.
  Binary behaviour belongs in `smoke.sh`.
- **Fixing the caller you are looking at leaves its siblings broken.** `0d23f86` fixed
  `bufferFlush` and never checked the CLI; three separate callers of newly gated commands were
  each missed by the agent that gated them. Grep every caller, always.
- **Two switches that must be "kept in sync by hand" is the bug this session is about.** A mirrored
  preview switch arrived in `doctor --fix`; collapsed into one function that describes and does.
- **Write the invariant against the real data first.** Three candidate naming rules were measured
  across all 14 actions; two produced legitimate false positives. Only "a word appearing nowhere
  in the table" had exactly one violation — the real one.

---

## NEXT — in order

1. **Open the menu and read it.** No test can, and five of this session's changes are menu rows.
   Check: the `Setup…` row, Recent Copies (4+ entries), and — if you ever unwire hooks — the
   `Agent status needs a hook` row.
   ```bash
   cd /Users/sxope/Documents/2026/Development/37.chute && ./Scripts/build-app.sh && ./Scripts/install.sh
   ```
2. **Move 5 needs two numbers from you, and only you have them.** The session switcher is still
   `jtbd: 0`, `savedMinutes: null` in `site/src/lib/cases.ts` — never costed, while holding 2.3%
   of measured value in 2,098 lines. You chose *measure it* over *shrink it*. Answer these and the
   ledger entry is ten minutes: **(a)** how many times a day do you go looking for which agent is
   waiting? **(b)** how long does finding it take without Chute? Until then `check:cases` keeps
   saying the figure is an estimate, correctly.
3. **The stopwatch — still only you.** Every `demo/out/gui/*.json` has `manual: null`, so all 25
   site figures remain ledger estimates. ~3 min, per `docs/13-RECORDING-BY-HAND.md`:
   ```bash
   cd /Users/sxope/Documents/2026/Development/37.chute && ./demo/gui/by-hand.sh
   ```
4. **Record the two new tapes.** `move-the-junk-an-agent-left` and `open-a-terminal-where-you-are`
   pass `make -C demo/gui check` under `PLAN=1` and have never met a real screen.
5. **Phase 0 — still blocking money, still yours.** Two CNAMEs (`dig +short chutedev.com` is still
   empty), Apple enrolment ($99, 24–48 h), Paddle, `hello@`/`keys@`, and the Ed25519 keypair —
   `Sources/ChuteCore/License.swift:28` is still `REPLACE_ME_BEFORE_RELEASE`.

---

## DECISIONS (and why) — do not re-litigate

- **`doctor --fix` is gated like the other four**, even though `--fix` is already opt-in. It runs
  `killall Finder`. A convention with one exception is not a convention.
- **The five `fix:` texts still say `chute doctor --fix`, not `--fix --force`.** Running it prints
  the preview AND names `--force` — the self-documenting two-step the audit praised in `ports`.
  `install.sh` got the flag because its surrounding sentence promises immediate action.
- **`bundle` and `unpack` were NOT renamed.** They are the two highest-value jobs and appear in
  every doc, the site and the demo tapes; a cross-repo migration whose only payoff is consistency
  with prose costs more than it buys. `buf flush` → `buf all` was taken because `flush` breaks all
  four clauses of the naming law and the GUI already says "Copy All N Together". `flush` stays as
  an undocumented alias, and smoke asserts both return identical text.
- **The comment marker is KEPT in unpacked file content.** `// src/c.ts` is part of the file the
  agent wrote; only the extracted path has it stripped.
- **Recent Copies stays hidden when empty, and now says so when LOCKED.** An expired trial used to
  make it and Local Servers vanish silently — indistinguishable from empty. The gate is unchanged;
  only the silence was.

## OPEN QUESTIONS FOR THE HUMAN

- `AgentCommands.swift` is still four features in one file, and there is still no About panel.
- A privileged helper for real CPU temperature remains open — a security surface bought with a
  number nobody has acted on. Rule 7 says no unless a decision follows.
- `ProcessMetrics.cpuNanos` still has no production caller. Keep as a validation convenience, or
  delete?
