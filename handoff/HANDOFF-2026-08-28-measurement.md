# PLAN — the next session: numbers that earn their place

Repo root: `/Users/sxope/Documents/2026/Development/37.chute`
Written 2026-08-28, end of session. Supersedes the menu-redesign plan, which shipped.

---

## Context

Today began with "why do we have Refresh Now?" and ended with the discovery that **both numbers
in the menu bar were wrong** — not slightly, and not in ways any test could see:

| | What it claimed | What was true | Why nothing caught it |
|---|---|---|---|
| CPU | `ps -o pcpu`, e.g. Chrome 21.4% | 0.5% measured over a real second | `pcpu` is a **lifetime average since the process started**. Anything busy an hour ago reads busy forever. |
| Memory | sum of `rss` across the tree | ×1.78–1.93 less | `rss` counts every shared page once per process, and a session is a tree of 24. |
| CPU, again | after the first fix: 2.4% on a pinned core | 100% | `pti_total_user` is in **mach ticks, not nanoseconds**. On Intel the timebase is 1/1 so the naive reading is correct — which is why it survives review on the machine most people write it on. |

**The systemic finding, and the reason this plan exists:** `Scripts/smoke.sh:169` asserts only that
the keys `cpuPercent` and `memoryBytes` **exist**. Every gate in this repo checks shape. None
checks magnitude. A number can be off by 24× and stay green forever.

So the next session is not "add more metrics". It is: **make the numbers true, make them
provable, and only ship the ones a decision follows from.**

---

## The doctrine — how to extract a meaningful number

Seven rules, each earned by a bug this session. They go in the header of `ProcessMetrics.swift`
so the next person inherits them rather than rediscovering them.

1. **Prefer a counter you diff over a gauge somebody else averaged.** `pcpu` is an average whose
   window you did not choose. Two samples and a measured interval is a number you own.
2. **Measure the interval; never assume it.** A sleeping menu-bar timer drifts, and a nominal 2 s
   used as a divisor prints spikes that never happened.
3. **Prefer the number the OS uses for the same decision.** `phys_footprint` is what jetsam kills
   on and what Activity Monitor displays — so a user checking your work sees the same figure.
4. **A refusal is not a zero.** Cross-uid `proc_pid_rusage` may return rc 0 with a **zeroed
   struct** rather than an error (see the open question below). Silent zeros are worse than gaps.
5. **Every unit conversion gets a test that fails on a wrong factor.** The 24× bug is invisible to
   review and obvious to a busy loop. `ProcessMetricsSuite` now burns a core and asserts the band.
6. **Validate once against an independent tool, by hand, and write down the date and the delta.**
   `footprint(1)` de-duplicates shared pages across a tree; it is the ground truth for our sum.
7. **A number with no decision attached does not ship.** This is what killed the battery
   temperature and the "0.4 of 16 cores" line. State the decision in the doc comment or delete it.

---

## The proven surface — measured on this machine, not assumed

Everything below was verified on macOS 14.6.1, Apple Silicon, uid 502, **no root, no
entitlements**. Timings are for 30 pids.

| Source | Gives | Cost | Verdict |
|---|---|---|---|
| `proc_pid_rusage` **V6** | footprint, **lifetime peak**, diskio, instructions, cycles, **`ri_energy_nj`**, `ri_proc_start_abstime` | **0.046 ms** | **Take.** V6 costs the same as the V4 we ship today. |
| `PROC_PIDVNODEPATHINFO` | **the process's real cwd** | 0.072 ms | Works. Not chosen this round — see below. |
| `PROC_PIDTASKALLINFO` | ppid, **uid**, start time, real name | 0.055 ms | Take — the uid is how rule 4 is enforced. |
| `proc_pidpath` | full executable path | 0.072 ms | Take, for `--user-data-dir` attribution. |
| `KERN_PROCARGS2` | full argv | 0.371 ms | Take, **cached** — argv never changes. |
| `getsid(2)` | session id, survives reparenting | trivial | Already shipped today. |
| `sysctl KERN_PROC_ALL` | ppid, pgid, tdev, start — no fork | **0.07 ms** | **Take** — replaces a 47 ms `ps` fork. |
| `nettop -P -L1` | bytes in/out per process | 15 ms | Possible, unprivileged. Not this round. |
| `powermetrics` | — | — | **Root only. Confirmed. Dead end.** |
| `task_for_pid` | — | — | **Denied without an entitlement we will not ask for.** |
| `ps -o sess=` | — | — | **Broken on macOS**: `e_sess` is NULL for non-root, prints 0 for everything. |

**The headline: `ri_lifetime_max_phys_footprint` is a real high-water mark.** Proved by forking a
child, allocating 2 GB, touching every page, freeing it, then sampling: footprint 2.2 MB,
lifetime max **2.00 GB**. That is the direct answer to *"why do you consume 9gb of memory?"* —
by the time you looked, the spike was gone and nothing in the system could tell you it had
happened.

---

## Decisions taken (yours, this session — do not re-litigate)

| Question | Chosen |
|---|---|
| Scope | **All four**: numbers deeper · make the menu testable · close the GTM gaps · prepare Phase 0 |
| Which numbers | **Peak memory** and **per-browser-instance grouping**. Not disk/energy, not cwd-naming. |
| Dispatch | **3 Sonnet + 2 Haiku, disjoint files.** I write every spec, run every gate, make every commit. |

**Considered and not chosen, recorded so it is a decision and not an oversight:** naming a session
from its real `cwd` instead of scraping the Terminal window title. It is a *correctness* issue of
the same class as the "Claude Code" string that turned out not to be ours — `project` comes from
splitting a window name on " — " at `TerminalAppAdapter.swift:115`. The API is proven and costs
0.0024 ms/pid. Raise it again when the window-title guess visibly misnames something.

---

## How the session runs

### Opening move — before any code

1. **`superpowers:brainstorming`** on one question only: *which decision does each proposed number
   change?* Anything without an answer is cut before it is specified. This is the filter that
   killed the battery temperature, applied on purpose instead of in hindsight.
2. Then **`superpowers:writing-plans`** to turn the survivors into the three specs below. A Sonnet
   agent is only as good as the spec, and the spec is mine to write.

### The specs — written first, to disk, before any agent starts

Each lives at `docs/specs/2026-08-29-<name>.md` and carries, per `~/.claude/rules/common/agents.md`:
the exact files it owns, the verification command, the baseline to beat, and *"report real
numbers"*. **A subagent's return value dies with the parent**, so every agent also writes its
findings to `handoff/agent-<name>.md` before finishing.

### Dispatch — one message, disjoint file sets, never two agents in one file

| Agent | Model | Owns | Must not touch |
|---|---|---|---|
| **A — metrics** | Sonnet | `Sources/ChuteCore/ProcessMetrics.swift` + `Sources/chutetests/ProcessMetricsSuite.swift` | anything else |
| **B — identity** | Sonnet | NEW `Sources/ChuteCore/ProcessIdentity.swift` + NEW `Sources/chutetests/ProcessIdentitySuite.swift` | ProcessMetrics |
| **C — menu model** | Sonnet | NEW `Sources/ChuteCore/StatusMenu.swift` + NEW suite; then `Sources/ChuteApp/SessionMenu.swift` | Core metrics files |
| **D — docs** | Haiku | `docs/14-PRODUCT-INVENTORY.xlsx` regen, `docs/12-CAPABILITY-MAP.md`, `handoff/NEXT.md` counts | any Swift |
| **E — sweep** | Haiku | the two missing tapes in `demo/gui/tapes/`, dead-code sweep | any Swift |

C is serialised *after* A and B land, because it consumes both. A and B are genuinely disjoint and
launch together in one message.

### Closing move — split-role review

`code-reviewer` and `security-reviewer` in parallel, then **`ponytail:ponytail-review`** for
over-engineering, then `superpowers:verification-before-completion` before any success claim. I
read the output and apply the fixes; the reviewers do not edit.

---

## The work

### 1 — Metrics that are true (Sonnet A)

- **Upgrade V4 → V6.** Same cost, and it carries `ri_energy_nj` and `ri_proc_start_abstime`.
- **Peak memory.** `ri_lifetime_max_phys_footprint` on `ProcessMetrics.Sample`, summed per session
  and shown on the row **only when the peak meaningfully exceeds the present** — e.g. `826 MB
  (peaked 6.1 GB)`. A peak equal to the current figure is not information.
- **Enforce rule 4.** Read `pbi_uid` from `PROC_PIDTASKALLINFO` and drop anything that is not
  ours *before* recording it. **First task: settle the contradiction** — my Swift probe reported
  `EPERM` for other users' pids, the research reported rc 0 with a zeroed struct. One of those is
  a silent wrong number. Determine which with the real struct, and write the test either way.
- **Pid-recycling safety** via `(pid, ri_proc_start_abstime)`, which is boot-relative and monotonic
  so an NTP step cannot alias two processes.
- **Kill the 47 ms `ps` fork.** One `sysctl KERN_PROC_ALL` gives ppid, pgid, tdev and start time in
  70 µs with no subprocess and no text parsing. Baseline to beat: **47 ms → under 1 ms.**

### 2 — Which browser is that (Sonnet B)

New `ProcessIdentity.swift`: `proc_pidpath`, cached `KERN_PROCARGS2`, ppid from
`PROC_PIDTASKALLINFO`.

- Group Chrome/Chromium by **`--user-data-dir`**, which appears **only on the browser process** —
  helpers must be walked up their ppid chain to find it. Label from the directory's basename, so
  Playwright shells, AdsPower and Dolphin each read as themselves.
- **State the limit in the code and in the UI copy:** profiles *inside* one Chrome instance are not
  attributable from process information. Renderers are per-site, not per-profile, and carry no
  profile flag. Chrome's own Task Manager can do it because it lives inside the browser. We will
  not guess.
- Feeds `SystemVitals.commandFamily`, so `mostly Google Chrome` becomes
  `mostly Chrome (mcp-chrome-9ebcc11)`.

### 3 — A menu a test can read (Sonnet C)

**51 menu-item decisions live in AppKit files that `chutetests` cannot link** — `Package.swift:18`
declares the test target against `ChuteCore` only, so all 11 files in `Sources/ChuteApp/` have zero
coverage. That is why `handoff/NEXT.md:126` still asks you to hand-verify the trial gate.

The pattern that already works is two files away: `ChuteActions.rows()` is pure data in ChuteCore,
and `FinderActionsSuite.swift:72` asserts eight rows, their titles and that no two share an icon —
headlessly, every build.

So: **`StatusMenu.model(sessions:trial:servers:recent:) -> [MenuNode]`**, pure, in ChuteCore.
`SessionMenu` renders `[MenuNode]` into `NSMenu` and decides nothing. Then assert, headlessly:

- item order and count for **licensed / trial day 10 / trial day 3 / expired**
- **opening twice produces the same count** — the regression test for the duplicate-menu bug
- no item is titled "Refresh"
- the trial row is absent on day 10 and present on day 3
- idle collapses past three; `Recent Copies` is absent when empty

### 4 — The plausibility gate (mine, and the point of all of this)

A new `Scripts/check-metrics.sh`, wired into `smoke.sh`, that would have caught **both** of today's
bugs:

- Sum of all sessions' memory **≤ `hw.memsize`** (48 GB here). Exceeding it means double counting.
- Any session's CPU **≤ `hw.logicalcpu` × 100** (1600 here).
- Spawn a known one-core load, assert the reading lands in **80–130%**. Catches a unit factor.
- Allocate a known 500 MB, assert footprint moves by **500 MB ± 20%**. Catches the other one.
- Record the `footprint(1)` cross-check for one real tree, with its date and delta, in
  `docs/12-CAPABILITY-MAP.md`.

### 5 — GTM gaps (Haiku D + E, and one thing only you can do)

- **7 of 25 cases still have no recording** — `move-the-junk-an-agent-left` and
  `open-a-terminal-where-you-are` have no tape and no policy; the other five are refused on purpose
  by `demo/gen-shorts.mjs`. Haiku E writes the two missing tapes.
- **Zero cases are backed by a two-sided stopwatch.** Every `demo/out/gui/*.json` has
  `manual: null`, so all 25 site figures are ledger estimates and `check-cases.mjs:135` says so.
  Only you can fix that: `./demo/gui/by-hand.sh`, ~3 minutes, per `docs/13-RECORDING-BY-HAND.md`.
- `onboard` and `resume` shipped with unit suites and **no smoke coverage** — I add them.
- No About panel (`handoff/NEXT.md:301`); `AgentCommands.swift` is still four features in one file.

### 6 — Phase 0, prepared not done (mine, then yours)

Everything scriptable, scripted; everything else a checklist with the exact click. Still blocking
money, still yours: the two CNAMEs (15 free minutes, `dig +short chutedev.com` is still empty),
Apple enrolment ($99, 24–48 h queue), Paddle, `hello@`/`keys@`, the Ed25519 keypair
(`License.swift:28` is still `REPLACE_ME_BEFORE_RELEASE`), the Worker.
**Bump `Version.swift:12` to 0.3.0 before any release** — `release.sh` refuses an existing tag and
`v0.2.0` is pushed. Never delete that tag; the Homebrew tap's sha256 comes from its tarball.

---

## Verification

```bash
cd /Users/sxope/Documents/2026/Development/37.chute && swift build -c release && swift run chutetests
cd /Users/sxope/Documents/2026/Development/37.chute && ./Scripts/smoke.sh
cd /Users/sxope/Documents/2026/Development/37.chute && CHUTE_HEADLESS=1 ./Scripts/smoke.sh
cd /Users/sxope/Documents/2026/Development/37.chute && ./Scripts/check-metrics.sh
cd /Users/sxope/Documents/2026/Development/37.chute && make -C demo/gui check && ./demo/verify.sh
cd /Users/sxope/Documents/2026/Development/37.chute/site && npm run build && npm run check:cases && npm run check:claims && npm run check:paddle
```

Baselines to beat, stated so an agent can report against them: **835 unit · 152 smoke · 128
headless · 12 delivery · 13 demo**, a sample under **1 ms** (from 47 ms), and a menu that opens in
under 300 ms with 11 sessions.

Every new guard perturbed to red and restored with a targeted edit — never `git checkout --`.
Then the two things no test can do: open the menu and read it, and compare one session's total
against Activity Monitor with both on screen.

---

## What I will refuse to build, and why

| Idea | Why not |
|---|---|
| Matching Activity Monitor's Energy Impact number | A proprietary blend of CPU, wakeups, GPU and display. `d(ri_energy_nj)/dt` ranks processes identically — rank, never claim the number. |
| `powermetrics` for per-process power | Root. Confirmed by running it. |
| Per-Chrome-**profile** memory | Renderers are per-site and carry no profile flag. Chrome's Task Manager can; process information cannot. Saying so beats guessing. |
| `uss` / per-region accounting | 25–29 ms **per process**, and psutil's own source says it can hang on a process you do not own. |
| A privileged helper for real CPU temperature | Still an open question for you (`NEXT.md:354`), and a helper is a security surface bought with a number nobody has acted on yet. |
