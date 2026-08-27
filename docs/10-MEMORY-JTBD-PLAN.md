# Memory JTBDs + every-macOS strategy — plan for the next session

Written 2026-08-27. Source: https://memory-diag.macupdate.com/ (Memory Diag, Rocky Sand Studio)
plus this repo's own evidence. Execute top to bottom in a fresh session; every task carries its
gate command. Nothing here is implemented yet except where marked DONE.

---

## PART A — what was extracted, and the verdict on each

Memory Diag is a free menu-bar memory monitor: last updated 2020, Intel-only, **1.8/5 stars**,
7.5k downloads. That rating is the most useful thing on the page: the *jobs* are real, the
*execution* failed. Extract the jobs, never the implementation.

| Memory Diag promise | The underlying job | Verdict for Chute |
|---|---|---|
| "Memory pressure meter" | *When my Mac gets slow, I want to know if memory is the reason, so I stop guessing.* | **ADOPT** — one measured phrase on the This-Mac line, same snapshot as the rows |
| "Notifications" on pressure | *Warn me BEFORE the slowdown, so I can act while the Mac is still usable.* | **ADOPT, with the agent twist** — Chute can name the guilty *session*, which no generic tool can |
| "List of apps with significant memory usage" | *Tell me WHO is eating the RAM, so I kill the right thing.* | **ADOPT** — "hungriest:" alongside the existing "busiest:", per-session memory is already DONE |
| "Dynamic menu bar icon" | *Let me see distress without opening anything.* | **ADOPT minimally** — the existing ⤓ badge gains one distress mark when pressure is elevated |
| "Optimize memory" / RAM cleaning | — | **REJECT.** Purging is root-only; "cleaners" force page-outs and make things worse. This is where the 1.8 stars come from. Chute diagnoses; macOS manages. |
| "Customizable themes" | — | **REJECT.** Not a job. |

**Chute's angle, one sentence:** generic monitors say *"memory pressure is high"*; Chute says
*"memory pressure is high because your `sntz_mockups` agent's Playwright run holds 3.2 GB —
here's the session, ⌥6 to focus it."* Attribution (`SystemVitals.attribute`, DONE 2026-08-27)
is the moat; these features are its payoff.

### New JTBD ledger rows (append to `docs/03-JTBD-LEDGER.md` when shipped)

| # | JTBD | Freq/day | Manual | Chute | Tier |
|---|---|---|---|---|---|
| 25 | "Why is my Mac slow/hot" → named culprit session | 4 | 90 s (Activity Monitor + guessing) | 2 s | T2 |
| 26 | Pre-slowdown memory warning naming the guilty agent | event | full slowdown + lost agent run | 0 s | T2 |

---

## PART B — feature design (ponytail-minimal, all no-root, zero dependencies)

Verified on this machine 2026-08-27 — add these rows to the verified-API table in
`docs/08-MACOS-COMPATIBILITY.md` when implementing:

| Signal | Command | Output seen |
|---|---|---|
| Pressure level | `sysctl -n kern.memorystatus_vm_pressure_level` | `1` (1 normal / 2 warn / 4 critical) |
| Free % | `/usr/bin/memory_pressure` (last line) | `System-wide memory free percentage: 58%` |
| Swap in use | `sysctl -n vm.swapusage` | `total = 5120.00M used = 4159.25M …` |
| Physical RAM | `sysctl -n hw.memsize` | `51539607552` |

### F1 — memory truth on the This-Mac line
- `/Users/sxope/Documents/2026/Development/37.chute/Sources/ChuteCore/SystemVitals.swift`:
  pure `parseSwapUsage(_:) -> (usedMB: Double, totalMB: Double)?`, pure
  `pressureLabel(level: Int, swapUsedMB: Double) -> String?`.
- Wording rule (same as thermal, decided 2026-08-27): **normal pressure says NOTHING.**
  Level 2 → `memory under pressure, N GB swapped`; level 4 → `memory critical, N GB swapped`.
  Append to `machineLine` behind the same one-snapshot contract.
- Tests in `Sources/chutetests/SystemVitalsSuite.swift` first (RED), fixture strings above.

### F2 — "hungriest:" beside "busiest:"
- Pure `hungriest(_ samples:) -> ProcessSample?` (max residentKB). Show on `machineLine` only
  when it holds > 10 % of `hw.memsize` — relative, never a hardcoded GB (coding-style rule).
- The 2 s live-refresh (DONE 2026-08-27) picks both up with zero extra work.

### F3 — pressure notification naming the guilty session
- In ChuteApp only: `DispatchSource.makeMemoryPressureSource(eventMask: [.warning, .critical])`
  — documented since 10.9, **but PROBE FIRST** (the repo rule: four integrations died on
  assumed behaviour). Throwaway: 20-line swift script, run `memory_pressure -S -l warn`
  (simulate, may need sudo — if so, test by opening apps) and confirm the handler fires.
- On event: one notification via existing `Notify.post` —
  `"Memory pressure high — biggest holder: sntz_mockups (3.2 GB). Click to see sessions."`
  Guilty session = max session memory from `SystemVitals.sample()` + attribution.
- **Debounce: at most one notification per 10 minutes** (a nagging monitor gets deleted), and
  never notify at level 1. State in memory, not on disk.

### F4 — badge distress mark
- `SessionMenu.badge` gains pressure: `⤓ 3` → `⤓! 3` when level ≥ 2. One character; the
  tooltip explains. (The open "template NSImage badge" HIG finding stays separate — do not
  couple these.)

### F5 — CLI + support report parity
- `chute sessions` summary already prints `machineLine` — F1/F2 flow in automatically.
- Add pressure level + swap to `chute doctor --report` extras, so "my Mac is slow" support
  issues arrive pre-diagnosed.

**Explicitly NOT building:** memory cleaner, purge button, themes, per-process kill from the
memory list (the servers submenu already owns kill), any polling daemon (menu-open + event
source only), any new dependency, any `@available` guard.

---

## PART C — the every-macOS strategy (how ALL features stay working on 13 → 26)

The floor stays **macOS 13** (`Package.swift`), the ceiling is whatever ships. The strategy has
five legs; the first three exist and only need extension.

1. **API floor by construction.** No `@available` anywhere (audited, still true). Every new API
   must predate 13: the F3 dispatch source is 10.9+, sysctls are ancient. Any API newer than 13
   is rejected at design time, not guarded at runtime. The CI matrix catches violations.

2. **Behaviour, not API, is the real risk — so every OS-specific behaviour lives behind a pure
   parser with captured fixtures.** `lsof`, `ps`, `launchctl list`, `pluginkit`, `sysctl`,
   `ioreg` output can drift per OS. All parsing is already pure
   (`LocalServers.parse*`, `SystemVitals.parse`, `parseLaunchdJobs`…). **New task: a
   fixture-harvest smoke section** — on every CI OS, run each real command, feed its live
   output through the parser, assert a sane parse (`ps` parses ≥ 5 rows, `launchctl list`
   parses ≥ 1 job, `sysctl` pressure returns 1/2/4). Drift then fails CI on the OS where it
   drifts, with the command named. ~20 lines in `Scripts/smoke.sh`, runs headless.

3. **The CI matrix is the version lab.**
   `/Users/sxope/Documents/2026/Development/37.chute/.github/workflows/macos-matrix.yml`
   runs build + unit + headless smoke on macOS 13/14/15. **Task: add `macos-26` runner** (check
   `https://github.com/actions/runner-images` for the label; add as `continue-on-error: true`
   first week, then required). CI covers: parsers, CLI, API removals. CI cannot cover:
   extension loading, TCC prompts, notifications, menu rendering.

4. **A VM checklist covers what CI cannot.** VirtualBuddy (free, Virtualization.framework,
   licence allows 2 VMs) with macOS 13 and 26 images. Per release, per VM, 10 minutes:
   - `./Scripts/install.sh` → right-click a file → **inline items with colored icons appear**
     (bitmap icons are pre-rendered @2x — verify no scaling artifacts on the newest OS)
   - `Copy Folder Tree ▸` submenu opens; one action runs; notification arrives as Chute
   - menu bar: sessions listed, This-Mac line shows cores/pressure, live-refresh ticks
   - `Local Servers ▸ Stop It` on a `brew services` daemon actually stops it
   - macOS 15.0/15.1 special: extension enabled via `chute doctor --fix` (no Settings UI exists)
   Record results as a dated table appended to `docs/08-MACOS-COMPATIBILITY.md`.

5. **Distribution is a version feature too.** Notarisation (NEXT.md item 1) is what makes 13→26
   installs uniform — without it every version test starts with a Gatekeeper fight. It stays
   the first execution item; nothing in this plan blocks on it except public release.

Known per-version traps already banked (do not re-derive): Extensions UI missing on 15.0–15.1;
appex container ACL pins code identity; `ps -o tty=` prints `??`; `pgrep -x` never matches
bundled apps; launchd KeepAlive respawn (bootout, `gui/$UID` domain — verify domain syntax on
13 in CI leg 2, it changed across 10.x but is stable 11+).

---

## PART D — execution order for the new session

0. `cd /Users/sxope/Documents/2026/Development/37.chute && cat handoff/NEXT.md docs/10-MEMORY-JTBD-PLAN.md`
1. **F1 + F2** (pure functions, TDD): tests RED in `SystemVitalsSuite` → implement → 
   `swift run chutetests` green → `./Scripts/build-app.sh && ./Scripts/install.sh` → menu shows
   pressure only when elevated. Gate: open Activity Monitor, compare swap number.
2. **F3 probe** (20-line throwaway, delete after) → then implement notification + 10-min
   debounce → gate: simulate pressure or open heavy apps, one banner arrives, names a session.
3. **F4 badge + F5 report** — small; same commit as F3.
4. **Fixture-harvest smoke** (Part C leg 2) → `CHUTE_HEADLESS=1 ./Scripts/smoke.sh` green.
5. **CI matrix + macos-26** (Part C leg 3) → push, watch the matrix run.
6. **Ledger + compat doc updates** (Part A table, Part B verified rows), handoff rewrite.
7. **VM checklist** (Part C leg 4) — needs the founder at the keyboard, schedule separately.

Rules of engagement, restated so the next session cannot drift: TDD (RED first), zero new
dependencies, never write outside `~/.chute` and the repo, never touch `~/.claude`, pure
parsers for anything OS-emitted, one commit per completed step, push before context runs low.
