# HANDOFF — measurement — 2026-08-28

STATE: `main` · commits `0d23f86 → 493a01c` · tree clean · **pushed**
Counts live in ONE place: `marketing/06-FACT-SHEET.md` §Verification. Re-derived from the gates
this session, not copied forward.

```bash
cd /Users/sxope/Documents/2026/Development/37.chute && swift build -c release && swift run -c release chutetests
cd /Users/sxope/Documents/2026/Development/37.chute && ./Scripts/smoke.sh
cd /Users/sxope/Documents/2026/Development/37.chute && CHUTE_HEADLESS=1 ./Scripts/smoke.sh
cd /Users/sxope/Documents/2026/Development/37.chute && ./Scripts/check-metrics.sh
cd /Users/sxope/Documents/2026/Development/37.chute && make -C demo/gui check && ./demo/verify.sh
```

## ONE-LINE GOAL

The numbers in the menu are true, provable by magnitude rather than by shape, and only shipped
where a decision follows from them.

---

## DONE (verified)

**The plan at `~/.claude/plans/ultra-please-execute-the-imperative-garden.md` is executed.** What
each claim is proved by:

| Thing | Proved by |
|---|---|
| Recent Copies no longer destroys itself | 3× `chute prompt ponytail` → 1 row; a different copy → 2 |
| rusage V4 → V6, free | 0.019 ms vs 0.020 ms per 30 pids |
| Peak memory ships | live in the menu: `911 MB memory (peaked 2.0 GB)` |
| The 117 ms `ps` fork is gone | `the listing costs 0.88 ms` — **133×** |
| Browser instances are distinguishable | four Chromium trees resolved at once (below) |
| The gate catches a real 24× bug | reintroduced `nanosPerTick = 1` → `moved 2.8%, expected 80–130%` |
| Chute agrees with Apple's own tool | `footprint -p`: 384 MB / 421 MB peak; Chute 383 MB / 421 MB |
| 51 menu decisions are testable | `StatusMenuSuite`, headless, every build |

**Numbers, measured on this machine, not assumed** — these corrected the plan and are the reason
the design is what it is:

- `p_comm` is **truncated to 16 chars**; 160 of 383 processes sit at the cap, every
  `chrome-headless-shell` among them. Names must come from `proc_pidpath`.
- `devname(3)` costs **0.45 ms per call**. 36 processes sat on **5** terminals — caching it is
  94% of the fork win (17.8 ms → 0.88 ms).
- Cross-uid `proc_pid_rusage` returns **EPERM**, not "rc 0 with a zeroed struct". 169 pids, 0
  foreign-uid successes. The shipped code was already right; the change is a test that pins it.
- `ps` fork was **117 ms**, not the 47 ms the plan estimated.

**The trap the plan did not know about, caught in the live menu:** Claude Code installs as
`~/.local/share/claude/versions/2.1.250` — the executable file *is* the version string — so every
agent row read `mostly 2.1.250`. The first fix (fall back to `p_comm`) **did not change the
menu**: `ps` prints argv[0], and `p_comm` here is `2.1.250` too. The name is in the path, one
level up. Now `mostly claude`.

**Browser identity, live, four trees at once:**
`Google Chrome` (default profile, no flag, correctly unlabelled) · `Google Chrome
(mcp-chrome-9ebcc11)` · `chrome-headless-shell (playwright_chromiumdev_profile-CZ2GLT)` · one
launched by hand. Four rows that used to be one bucket called "Google Chrome".

**Split-role review found five real defects, all fixed in `493a01c`** — including a data race on
`SystemVitals.previous` (locked two other caches in the same commit and missed the oldest shared
state), a refusal reading as a **zero** in the file whose header states rule 4, a **false privacy
claim** in `BufferMenu.swift` (`chute buf add` *does* read the pasteboard), and `~/.chute/buffer`
sitting **world-readable** at 755/644 — now 0700/0600, and it repairs existing installs.

---

## TRAPS — paid for once, do not pay again

- **`p_comm` looks like the answer and is truncated at 16.** A listing built from it silently
  stops recognising Chrome. → `proc_pidpath`, then `ProcessMetrics.programName`.
- **A path basename is not always a program name.** Version-named binaries. → `programName`.
- **`devname` is expensive per call, not per distinct device.** → the cache; the timing assertion
  in `ProcessMetricsSuite` fails if it is removed.
- **A guard that stays green when you reintroduce the bug is not a guard.** The truncation test
  first looked for a 16-char name ending in `-`; swapping back to `p_comm` left it green. Rewritten
  to assert some name *exceeds* 16, which `p_comm` cannot produce by construction.
- **A gate that cries wolf gets ignored.** `check-metrics` check 2 first read "the busiest
  session" — that session's whole tree — and went red under load. Now a before/after delta,
  best of three: 94.6 / 100.8 / 97.6 / 98.6 / 98.8 over five runs.
- **`createDirectory` does not change the mode of a directory that already exists.** A permissions
  fix that only protects fresh installs protects nobody who already used the feature.
- **An unwired pure model proves nothing.** `ProcessIdentity` arrived with 47 tests and zero
  callers; so did `StatusMenu` until it was rendered. Wire it, then verify in the product.

---

## NEXT — in order

1. **Open the menu and read it.** No test can do this, and the render half still links AppKit.
   The point of `StatusMenu` is that rendering no longer *decides* anything, not that it is
   covered. Check: session rows, ⌥ alternates, Recent Copies, the idle submenu past three.
   ```bash
   cd /Users/sxope/Documents/2026/Development/37.chute && ./Scripts/build-app.sh && ./Scripts/install.sh
   ```
2. **Compare one session against Activity Monitor with both on screen.** The automated half is
   `./Scripts/check-metrics.sh`; the by-hand cross-check against `footprint(1)` is recorded with
   its date and delta in `docs/12-CAPABILITY-MAP.md` §F. Append a row when metrics code changes.
3. **The stopwatch — only you can do this.** Every `demo/out/gui/*.json` still has
   `manual: null`, so all 25 site figures remain ledger estimates and `check-cases.mjs` says so.
   ~3 minutes, per `docs/13-RECORDING-BY-HAND.md`:
   ```bash
   cd /Users/sxope/Documents/2026/Development/37.chute && ./demo/gui/by-hand.sh
   ```
4. **Record the two new tapes.** `move-the-junk-an-agent-left` and `open-a-terminal-where-you-are`
   are written and pass `make -C demo/gui check` under `PLAN=1`, but have never been run against a
   real screen.
5. **Phase 0 — still blocking money, still yours.** Two CNAMEs (`dig +short chutedev.com` is
   still empty), Apple enrolment ($99, 24–48 h), Paddle, `hello@`/`keys@`, the Ed25519 keypair —
   `Sources/ChuteCore/License.swift:28` is still `REPLACE_ME_BEFORE_RELEASE` — and the Worker.

---

## DECISIONS (and why) — do not re-litigate

- **Peak memory shows only when it dwarfs the present** (`peakWorthShowing` 1.5, floor 512 MB).
  A peak equal to the present is not information; that is how the old always-on suffix earned
  deletion.
- **Per-Chrome-*profile* memory will not be built.** Renderers are per-site, carry no profile
  flag, and the profile lives in Chrome's in-process state. Chrome's Task Manager can do it only
  because it runs inside the browser. Saying so beats guessing.
- **`parse(ps:)` stays** even though `ps` is gone. It is pure, it is what the fixture tests
  exercise, and a pure column parser costs nothing to leave standing.
- **cwd-based session naming: considered, not chosen.** `project` comes from splitting a window
  title on " — " at `TerminalAppAdapter.swift:115`. The API is proven and costs 0.0024 ms/pid.
  Raise it again when the window-title guess visibly misnames something. Recorded so it is a
  decision, not an oversight.
- **Refused, with reasons:** Activity Monitor's Energy Impact (proprietary blend — rank by
  `d(ri_energy_nj)/dt`, never claim the number), `powermetrics` (root, confirmed by running it),
  `task_for_pid` (entitlement we will not ask for), `uss` (25–29 ms *per process*).

---

## OPEN QUESTIONS FOR THE HUMAN

- `AgentCommands.swift` is still four features in one file, and there is no About panel
  (`NEXT.md:301`). Worth a session, or leave them?
- A privileged helper for real CPU temperature is still open (`NEXT.md:354`). It is a security
  surface bought with a number nobody has acted on — rule 7 says no unless a decision follows.
- `ProcessMetrics.cpuNanos` has no production caller now that `snapshot()` carries it. Keep as a
  test/validation convenience, or delete?
