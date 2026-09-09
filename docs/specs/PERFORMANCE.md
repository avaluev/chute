# The menu-open hot path — measured, not guessed

Every number below came from `Scripts/bench.swift`, run on this machine (macOS, Apple Silicon,
2026-09-09) with a real process table (420–460 processes at the time of each run, 80–90
tty-attached — this machine runs a lot of agents), real `~/.claude` transcripts, and Terminal.app
actually open with 13–15 windows across many tabs. No mocks for anything that has a real syscall
or a real subprocess behind it; `StatusMenu.model`'s fixture is the one exception, and it is real
data shaped like a session, not invented numbers (see "the 13-session fixture" below).

```
cd /Users/sxope/Documents/2026/Development/37.chute && Scripts/bench.sh
```

`Scripts/bench.sh` builds the `bench` SwiftPM target (`swift build -c release --product bench`,
added in `Package.swift`) and runs it. `bench` exists as a package target rather than a
free-standing script because it has to `import ChuteCore`, and a single `swift file.swift` cannot
link a local package's library target. Every benchmark runs 20 iterations after warmup and reports
the **median and p90** — not the mean, because one slow syscall (a scheduler hiccup, a page fault)
skews a mean of 20 samples by itself and the median shrugs it off.

## The hot path, restated precisely

`AppDelegate.menuWillOpen` → `populateBody` (`Sources/ChuteApp/main.swift:102`) runs **synchronously
on the main thread**, before AppKit shows the menu — the click is what "hides" this cost, per that
file's own comment at `main.swift:325`. It is genuinely on the path the user is waiting on, once,
per open:

```
SystemVitals.sample()            — one process-table read, shared with discover() below
TerminalAppAdapter.discover()    — isAppRunning + osascript + SessionCwd.map
StatusMenu.model(...)            — pure
SessionMenu.render(...)          — AppKit
```

The 2-second `LiveVitals` timer while the menu stays open is a **separate, lighter** thing: it
calls only `SystemVitals.sample()`, off the main thread (`main.swift:349`), never `discover()` and
never the AppleScript round-trip. That distinction matters for prioritization — the ~200 ms
AppleScript cost is paid once per menu open, not every 2 seconds.

`AgentTranscript` reads are **not** on this path at all: `populateBody` only calls
`TranscriptStore.cached` (cache-only, never touches disk); the real read happens after `render`
returns, on a background `.utility` queue (`main.swift:153`). Verified still true by reading the
code, not assumed.

## BEFORE

| what | median | p90 | n |
|---|---:|---:|---:|
| `SystemVitals.sample()` | 6.0 ms | 6.6 ms | 20 |
| `SessionCwd.map(...)` (real `proc_pidinfo`) | 0.30 ms | 0.31 ms | 20 |
| `ProcessIdentity.workingDirectory` × 89 tty pids | 0.08 ms | 0.09 ms | 20 |
| `AgentTranscript.readFile` (20.1 MB, 3,509 records) | 500 ms | 508 ms | 20 |
| `StatusMenu.model(...)` (13-session fixture) | 0.50 ms | 0.57 ms | 20 |
| **osascript round-trip alone** | **201 ms** | **208 ms** | 20 |
| `isAppRunning(...)` alone (`ps -Ao comm` fork) | **102 ms** | 106 ms | 20 |
| `TerminalAppAdapter().discover(...)` (whole thing) | **317 ms** | 326 ms | 20 |

`discover()`'s cost was `isAppRunning` (102 ms) + osascript (201–221 ms) + the rest (≈6 ms) ≈
310–330 ms, which is what "whole thing" measured. **Everything Chute does around the AppleScript
call cost about 6 ms; the two subprocess round-trips cost the other ~303–320 ms.**

## What dominated, and what changed

**`isAppRunning` was shelling out to `ps -Ao comm` on every single menu open**
(`Sources/ChuteCore/TerminalAppAdapter.swift`), listing every process on the machine as text and
substring-matching it — the exact class of bug `ProcessMetrics.listing()` already fixed once (see
that file's own "THE 117 ms `ps` FORK, DELETED" section) — except this second `ps` fork was never
caught, because it predates `ProcessMetrics` and nothing had ever timed it in isolation. Measured:
**102 ms**, every menu open, before Chute had even asked Terminal.app a single question.

Fixed to `ProcessMetrics.allPIDs()` + `ProcessIdentity.executablePath(_:)` — two syscall-based
primitives this codebase already has and already trusts, recomposed rather than reimplemented.
`ProcessMetrics.listing()` was NOT reused directly: it is deliberately scoped to `getuid()`
("another user's processes were never ours to report" — its own header), and `isAppRunning` has to
see root's `launchd` too (`TerminalParseSuite` pins exactly that assertion). `proc_pidpath` is the
one primitive in this codebase that is verified to cross the ownership boundary, so `allPIDs()`
(no uid filter) is the correct pairing.

**Fixing this exposed a second, real, pre-existing bug**, not introduced by this change:
`ProcessMetrics.allPIDs()` divided `proc_listallpids`'s second call by
`MemoryLayout<Int32>.size` a second time. That call returns a **pid count** on both invocations
(the probe with `buffer == nil` and the real one), never a byte count — so a machine that actually
listed ~628 processes was reporting **157** (628 ÷ 4), an arbitrary kernel-ordered quarter with no
guarantee of which pids survived. It was invisible until now because the only production-adjacent
caller, `snapshot(pids: nil)`, feeds `proc_pid_rusage`, which refuses non-own-uid pids anyway — so
losing 3/4 of a list that was mostly going to be refused regardless never moved any assertion.
`isAppRunning` was the first caller to ask `allPIDs()` a question the truncation could actually get
wrong ("is root's launchd running?"), and `TerminalParseSuite`'s existing fixed assertion on that
exact question caught it immediately — this file's suite did not need a new test, the old one did
its job. Fixed in `ProcessMetrics.swift`; both callers (`snapshot(pids: nil)` and `isAppRunning`)
now see the whole machine.

Neither fix touches `Shell.swift` (not owned, and shared by many other call sites) or the
AppleScript itself.

## AFTER

| what | median | p90 | n | Δ vs before |
|---|---:|---:|---:|---:|
| `SystemVitals.sample()` | 6.6 ms | 7.6 ms | 20 | ~unchanged |
| `SessionCwd.map(...)` | 0.30 ms | 0.34 ms | 20 | ~unchanged |
| `ProcessIdentity.workingDirectory` × 89 | 0.08 ms | 0.09 ms | 20 | ~unchanged |
| `AgentTranscript.readFile` (20.2 MB, 3,660 rec.) | 488 ms | 495 ms | 20 | ~unchanged (not on this path) |
| `StatusMenu.model(...)` (13-session fixture) | 0.48 ms | 0.57 ms | 20 | ~unchanged |
| osascript round-trip alone | 188 ms | 194 ms | 20 | ~unchanged (see below) |
| **`isAppRunning(...)` alone** | **1.9 ms** | 2.4 ms | 20 | **−100 ms, ~53×** |
| **`TerminalAppAdapter().discover(...)` (whole)** | **200 ms** | 203 ms | 20 | **−117 ms, ~1.6×** |

The synchronous, main-thread cost of opening the Chute menu dropped from **~317 ms to ~200 ms
median** on this machine — a real ~37% cut to the number the user is actually waiting on, from one
bug fix in the file's own code, not from touching AppleScript, `Shell.swift`, or anything AppKit.

## What was deliberately NOT optimized, and why

**The osascript round-trip itself (≈185–220 ms, now ~94% of `discover()`'s cost).** Isolated with a
trivial script (`osascript -e 'return 1'`, ~20 ms — pure process-spawn overhead) against the real
discovery script (~185–220 ms): the gap is Terminal.app itself enumerating windows and, per tab,
`processes of t as string` — genuine AppleEvent handling cost inside Terminal.app, not anything on
Chute's side of the pipe. This machine had 13–15 Terminal windows open across the runs above, which
is realistically why the number moves between runs. No safe lever exists within this task's own
rules ("no new dependencies," "no concurrency that could race" — `NSAppleScript` in-process would
still pay Terminal.app's own query cost for ~10% less spawn overhead, for a real behavior-change
risk against a resiliency property — `try` blocks tolerating a tab closing mid-scan — that has no
test coverage through the real AppleScript path). **Left alone.**

**`AgentTranscript.readFile`/`parse` (≈480–500 ms on the largest real transcript here).** VERIFIED
FALSE the "~37 ms" claim in the code comments: that number was a Python reimplementation's
measurement, cited honestly as such in `AgentTranscript.swift`'s own header, but repeated
elsewhere (`TranscriptStore`'s header, `main.swift`) as if it were this Swift function's cost. The
real number is **~13× higher**. Split to find out why: `String(contentsOfFile:)` is ~10 ms; the
remaining ~480 ms is `JSONSerialization` building a full `[String: Any]` Foundation object graph
per line — including large nested tool inputs/outputs and pasted file content the parser never
reads — to extract five top-level strings and two usage counters. **This is real, and it is NOT on
the menu-open hot path**: verified by reading `main.swift:102-159` that `populateBody` calls only
`TranscriptStore.cached` (cache-only), and the real read is dispatched to a background `.utility`
queue *after* `SessionMenu.render` has already returned. Per this task's own scope (measure and
optimize the menu-open path; "no speculative optimization"), a parser rewrite here is out of
scope — it would touch every field this struct exposes, for a cost the user never waits on.
Corrected the three false "37 ms" comments to the real, dated number instead
(`AgentTranscript.swift` ×2, `main.swift` ×1). Flagged, not fixed.

**`SystemVitals.sample()` (~6–6.6 ms).** Profiled into its parts (`listing()` ~2.6 ms, `getsid()`
loop ~0.05 ms, `snapshot(pids:)` ~0.4–0.55 ms, `attribute(rows)` ~0.05 ms) specifically to chase two
plausible-looking hypotheses — both measured false, on this machine, against this machine's own
real process names:

- *"`sample()` rebuilds a `[pid:ppid]` map that `attribute()` already built internally — a
  duplicate pass."* True in shape, irrelevant in cost: rebuilding it measured **0.017–0.022 ms**
  for 400+ pids. Not touched.
- *"`browserInstance`'s `.lowercased()` gate, run once per process row (400+ times a sample),
  allocates a new String where `.range(of:options:.caseInsensitive)` would not."* Measured the
  **opposite**: `.range(of:options:)` was **~4× slower** (1.9–2.2 ms vs 0.47–0.60 ms) than the
  `.lowercased()` + `.contains` the code already ships, over these real process names. The
  as-shipped code is the faster of the two. Not touched — and the alternative was never applied.

6–6.6 ms total is under 2% of the dominant ~200 ms `discover()` cost and imperceptible on its own;
nothing inside it stood out as a real win once measured, so nothing was changed.

**`SessionCwd.map`, `ProcessIdentity.workingDirectory`, `StatusMenu.model`** — all sub-millisecond
on real data (0.3–0.6 ms). Already fast enough. Left alone.

## Correctness

`swift build -c release && swift run -c release chutetests` — **1324/1324**, before and after every
change in this file. `TerminalParseSuite`'s existing `isAppRunning` assertions (launchd present,
a nonexistent app absent) is what caught the `allPIDs()` bug — no new test was written for it,
because the coverage already existed and simply hadn't been exercised through that path before.

## Files touched

- `Sources/ChuteCore/TerminalAppAdapter.swift` — `isAppRunning` rewritten off `ps -Ao comm`;
  `discoveryScript` made `public` so the benchmark can time the exact production script.
- `Sources/ChuteCore/ProcessMetrics.swift` — `allPIDs()` double-division bug fixed.
- `Sources/ChuteCore/AgentTranscript.swift` — two false "37 ms" claims corrected with real numbers
  and a pointer to this document.
- `Sources/ChuteApp/main.swift` — one comment, same correction (not otherwise in scope; touched
  only because it carried the same false claim this task asked to verify).
- `Package.swift` — new `bench` executable target (`Scripts/bench.swift`, dependencies:
  `["ChuteCore"]`), with the rest of `Scripts/` explicitly excluded so `swift build` stays free of
  the "unhandled files" warning pointing a target at that directory would otherwise cause forever.
- `Scripts/bench.swift`, `Scripts/bench.sh` — new.
