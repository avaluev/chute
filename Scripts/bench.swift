import ChuteCore
import Darwin
import Foundation

// THE HOT-PATH BENCHMARK — see docs/specs/PERFORMANCE.md for the report this feeds.
//
// Run with `Scripts/bench.sh` (which builds release and runs this). Every number below is REAL:
// this machine's own process table, this machine's own transcripts, Terminal.app actually
// running. No mocks — the whole point is to measure what the menu really pays, not what a
// fixture says it should pay.
//
// MEDIAN AND P90, NOT MEAN. One slow syscall (a page fault, a GC-ish stall, the scheduler
// preferring another process for a tick) skews a mean of 20 samples by itself; the median
// shrugs it off and the p90 still shows it happened.

// ── THE HARNESS ─────────────────────────────────────────────────────────────────────────────

struct BenchResult { let name: String; let median: Double; let p90: Double; let n: Int }

/// Runs `block` `warmup` times (discarded — JIT-free Swift has no warmup cost of its own, but the
/// first call into a lazily-initialised static, like `ProcessMetrics.nanosPerTick` or
/// `SystemVitals.previous`, is not representative of the other nineteen) then `iterations` times,
/// timed with `DispatchTime` (monotonic, sub-microsecond resolution — `Date()` is neither).
@discardableResult
func measure(_ name: String, iterations: Int = 20, warmup: Int = 2,
            _ block: () -> Void) -> BenchResult {
    for _ in 0..<warmup { block() }
    var ms: [Double] = []
    ms.reserveCapacity(iterations)
    for _ in 0..<iterations {
        let t0 = DispatchTime.now().uptimeNanoseconds
        block()
        let t1 = DispatchTime.now().uptimeNanoseconds
        ms.append(Double(t1 - t0) / 1_000_000)
    }
    ms.sort()
    let median = ms[ms.count / 2]
    let p90 = ms[min(ms.count - 1, Int((Double(ms.count) * 0.9).rounded(.up)) - 1)]
    let result = BenchResult(name: name, median: median, p90: p90, n: iterations)
    print(row(result))
    return result
}

func row(_ r: BenchResult) -> String {
    let width = max(46, r.name.count + 1)
    let name = r.name.padding(toLength: width, withPad: " ", startingAt: 0)
    let med = String(format: "%9.3f ms", r.median)
    let p90 = String(format: "%9.3f ms", r.p90)
    return "  \(name) median \(med)   p90 \(p90)   (n=\(r.n))"
}

func heading(_ s: String) { print("\n\(s)") }

print("BENCH — \(Date()) — \(ProcessInfo.processInfo.hostName)")
print("run: cd \(FileManager.default.currentDirectoryPath) && Scripts/bench.sh")

// ── SystemVitals.sample() ───────────────────────────────────────────────────────────────────
//
// The whole-menu process listing: one for the menu, shared with `discover()` below. First call
// pays `SystemVitals.settleSeconds` (150 ms) because there is no previous CPU snapshot yet — that
// is a real, one-time cost on cold start, not a per-open cost, so it is absorbed by `warmup`
// rather than reported as if it happened on every menu open.
heading("1. SystemVitals.sample()  — one process-table read")
measure("SystemVitals.sample()") { _ = SystemVitals.sample() }
let liveSamples = SystemVitals.sample()
print("  (\(liveSamples.count) processes, \(liveSamples.filter { !$0.tty.isEmpty }.count) tty-attached, on this machine)")
// DIAGNOSTIC — not one of the six named benchmarks, kept because it is what SETTLED whether
// there was anything in `sample()` worth changing (there was not; see docs/specs/PERFORMANCE.md
// "what was deliberately not optimized"). Splits `sample()`'s pieces so a slow total does not get
// blamed on the wrong one, and pins two specific hypotheses that looked plausible and measured
// false: a duplicate [pid:ppid] dictionary build, and `browserInstance`'s `.lowercased()` gate.
let pidsForProfile = ProcessMetrics.listing().map { Int32($0.pid) }
measure("  » listing() alone") { _ = ProcessMetrics.listing() }
measure("  » getsid() loop, \(pidsForProfile.count) pids") {
    for p in pidsForProfile { _ = getsid(p) }
}
measure("  » snapshot(pids:) alone") { _ = ProcessMetrics.snapshot(pids: pidsForProfile) }

var rowsForProfile: [ProcessSample] = []
for row in ProcessMetrics.listing() {
    var s = ProcessSample(pid: Int(row.pid), ppid: Int(row.ppid), command: row.command,
                          tty: row.tty, cpuPercent: 0, residentKB: 0)
    let sid = getsid(pid_t(row.pid))
    if sid > 0 { s.sid = Int(sid) }
    rowsForProfile.append(s)
}
measure("  » attribute(rows) alone") { _ = SystemVitals.attribute(rowsForProfile) }
let treeForProfile = SystemVitals.attribute(rowsForProfile)
// HYPOTHESIS: `sample()` rebuilds a [pid:ppid] map after `attribute()` already built an
// equivalent one internally for its own ppid walk — a textbook "repeated pass" candidate.
// MEASURED FALSE: rebuilding it costs under 0.03 ms for 400+ pids. Not touched — see PERFORMANCE.md.
measure("  » a 2nd [pid:ppid] dict build over the same tree (duplicate-pass hypothesis)") {
    var m: [Int: Int] = [:]
    for p in treeForProfile { m[p.pid] = p.ppid }
    _ = m
}
// HYPOTHESIS: `browserInstance`'s gate — `name.lowercased()` (a heap-allocating, Unicode-aware
// case fold) then four `.contains`, once per process row — is the missing chunk of `sample()`'s
// cost, and `.range(of:options:.caseInsensitive)` (no upfront allocation) would be cheaper.
// MEASURED FALSE, and the OPPOSITE of the guess: `.range(of:options:)` measured ~4x SLOWER than
// the code as it stands today, on this machine, over these real names. Not touched.
let namesForProfile = treeForProfile.map(\.command)
let markers = ["chrome", "chromium", "brave", "edge"]
measure("  » browserInstance gate as shipped: .lowercased() + .contains x4") {
    for n in namesForProfile {
        let lower = n.lowercased()
        _ = markers.contains { lower.contains($0) }
    }
}
measure("  » browserInstance gate, alternative: .range(of:options:.caseInsensitive)") {
    for n in namesForProfile {
        _ = markers.contains { n.range(of: $0, options: .caseInsensitive) != nil }
    }
}

// ── SessionCwd.map with the real syscall ────────────────────────────────────────────────────
heading("2. SessionCwd.map(...) — real proc_pidinfo syscall per tty-attached process")
measure("SessionCwd.map(liveSamples, cwdOf: workingDirectory)") {
    _ = SessionCwd.map(liveSamples, cwdOf: ProcessIdentity.workingDirectory)
}

// ── ProcessIdentity.workingDirectory, one call per tty pid, unamortised ────────────────────
heading("3. ProcessIdentity.workingDirectory(_:) — every tty-attached pid, called directly")
let ttyPids = liveSamples.filter { !$0.tty.isEmpty }.map { Int32($0.pid) }
measure("workingDirectory over \(ttyPids.count) tty pids") {
    for pid in ttyPids { _ = ProcessIdentity.workingDirectory(pid) }
}

// ── AgentTranscript reads — VERIFY the "~37 ms" claim in the doc comments ──────────────────
//
// AgentTranscript.swift and Sources/ChuteApp/main.swift both cite "37 ms" for a full transcript
// parse — but AgentTranscript.swift's own header says that number came from a Python
// reimplementation ("a full parse of it takes 37 ms — in Python"), not the Swift code that
// actually ships. This finds the largest REAL transcript on this machine and times the real
// `AgentTranscript.readFile` against it.
heading("4. AgentTranscript.readFile(_:) — the largest real transcript on this machine")
let projectsDir = NSHomeDirectory() + "/.claude/projects"
func largestTranscript(under dir: String) -> (path: String, bytes: Int)? {
    guard let e = FileManager.default.enumerator(atPath: dir) else { return nil }
    var best: (String, Int)?
    for case let rel as String in e where rel.hasSuffix(".jsonl") {
        let full = "\(dir)/\(rel)"
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: full),
              let size = attrs[.size] as? Int else { continue }
        if best == nil || size > best!.1 { best = (full, size) }
    }
    return best.map { (path: $0.0, bytes: $0.1) }
}
if let (path, bytes) = largestTranscript(under: projectsDir) {
    let mb = Double(bytes) / 1_048_576
    let records = (try? String(contentsOfFile: path, encoding: .utf8))?
        .split(separator: "\n", omittingEmptySubsequences: true).count ?? 0
    print("  \(String(format: "%.1f", mb)) MB, \(records) records — \(path)")
    measure("AgentTranscript.readFile(_:) on that file", iterations: 20, warmup: 1) {
        _ = AgentTranscript.readFile(path)
    }
    // SPLIT: is the cost reading the file, or parsing it? `readFile` is two steps —
    // `String(contentsOfFile:)` then `parse(_:)` — and both are public, so each can be timed
    // alone to find out which one the 37 ms claim actually undercounts.
    let fileText = (try? String(contentsOfFile: path, encoding: .utf8)) ?? ""
    measure("  ...just String(contentsOfFile:)", iterations: 20, warmup: 1) {
        _ = try? String(contentsOfFile: path, encoding: .utf8)
    }
    measure("  ...just AgentTranscript.parse(text)", iterations: 20, warmup: 1) {
        _ = AgentTranscript.parse(fileText)
    }
    print("  NOTE: repeat reads of the SAME file benefit from the OS page cache — the FIRST")
    print("  (cold) read is the one that matters for \"does this ever run on the main thread\".")
    let t0 = DispatchTime.now().uptimeNanoseconds
    _ = AgentTranscript.readFile(path)
    let cold = Double(DispatchTime.now().uptimeNanoseconds - t0) / 1_000_000
    print("  a fresh single read just now: \(String(format: "%.3f", cold)) ms")
} else {
    print("  no transcripts found under \(projectsDir) — nothing to measure")
}

// ── StatusMenu.model over a realistic 13-session fixture ───────────────────────────────────
//
// 13 is not a round number picked for the report — it is how many tty-attached sessions THIS
// machine actually has open right now (see the process count printed above). A pure function:
// no syscalls, no disk, so this isolates what StatusMenu.model — sorting, row-building,
// `clampedProjectName`'s AppKit text measurement — costs on its own.
heading("5. StatusMenu.model(...) — 13-session fixture")
func fixtureSession(_ project: String, _ state: SessionState, tty: String, agent: String?) -> Session {
    Session(key: "Terminal:1:\(tty)", kind: .terminalApp, windowID: 1, tabIndex: 1, tty: tty,
           project: project, title: project, agent: agent, busy: state == .working,
           state: state, since: Date().addingTimeInterval(-Double.random(in: 30...5400)),
           sessionID: "sess-\(tty)",
           cwd: "/Users/x/Documents/2026/Development/\(project)/apps/web/src/components")
}
let thirteen: [Session] = [
    fixtureSession("chute", .working, tty: "ttys000", agent: "claude"),
    fixtureSession("studylock", .blocked, tty: "ttys001", agent: "claude"),
    fixtureSession("sntz_mockups", .waiting, tty: "ttys002", agent: "claude"),
    fixtureSession("chute", .working, tty: "ttys003", agent: "codex"),
    fixtureSession("studylock", .idle, tty: "ttys004", agent: nil),
    fixtureSession("sntz_mockups", .working, tty: "ttys005", agent: "claude"),
    fixtureSession("chute", .unknown, tty: "ttys006", agent: "cursor"),
    fixtureSession("studylock", .working, tty: "ttys007", agent: "claude"),
    fixtureSession("sntz_mockups", .idle, tty: "ttys008", agent: nil),
    fixtureSession("chute", .waiting, tty: "ttys009", agent: "claude"),
    fixtureSession("studylock", .working, tty: "ttys010", agent: "gemini"),
    fixtureSession("sntz_mockups", .blocked, tty: "ttys011", agent: "claude"),
    fixtureSession("a-very-long-repository-name-that-tests-the-column-clamp", .working,
                   tty: "ttys012", agent: "claude"),
]
func fixtureLoad(_ tty: String) -> SessionLoad {
    let h = abs(tty.hashValue)
    return SessionLoad(cpuPercent: Double(h % 200), residentBytes: UInt64(500_000_000 + (h % 4_000_000_000)),
                       processes: 3, top: (command: "node", bytes: 300_000_000), peakBytes: 0)
}
measure("StatusMenu.model(sessions: thirteen, ...)") {
    _ = StatusMenu.model(sessions: thirteen, loadFor: fixtureLoad,
                         sessionCommands: { _ in [("copyResume", "Copy Resume Command")] },
                         detailFor: { s in s.agent ?? "shell" })
}

// ── The osascript round-trip, in isolation ──────────────────────────────────────────────────
//
// `TerminalAppAdapter.discover()` = this script, over Shell.run, PLUS `SystemVitals.sample()`
// PLUS `SessionCwd.map`. Timing the exact same script text alone (not `discover()`'s wrapper)
// isolates what fraction of the menu-open cost is genuinely "waiting on Terminal.app to answer
// AppleScript" versus everything Chute does around it.
heading("6. the osascript round-trip, in isolation")
if isAppRunning(bundleExecutable: "Terminal.app/Contents/MacOS/Terminal") {
    measure("osascript -e <discoveryScript>", iterations: 20, warmup: 1) {
        _ = Shell.run("osascript", ["-e", TerminalAppAdapter.discoveryScript])
    }
    // `discover()`'s FIRST act, every call, is `isAppRunning`. It used to be its own `ps -Ao comm`
    // fork — measured 102 ms on this machine, a second subprocess on top of the osascript one —
    // now `proc_listallpids` + `proc_pidpath`, ~2 ms. Isolated so a future regression here shows
    // up as its own line instead of hiding inside "discover() whole".
    measure("  » isAppRunning(...) alone", iterations: 20, warmup: 1) {
        _ = isAppRunning(bundleExecutable: "Terminal.app/Contents/MacOS/Terminal")
    }
} else {
    print("  Terminal.app is not running — nothing to measure. Open a Terminal window and re-run.")
}

// ── the whole thing, for scale ──────────────────────────────────────────────────────────────
heading("7. TerminalAppAdapter().discover(...) — sample() + osascript + SessionCwd.map together")
if isAppRunning(bundleExecutable: "Terminal.app/Contents/MacOS/Terminal") {
    measure("discover(hooks: [:], now: Date())", iterations: 20, warmup: 1) {
        _ = try? TerminalAppAdapter().discover(hooks: [:], now: Date())
    }
} else {
    print("  Terminal.app is not running — nothing to measure.")
}

print("\ndone.")
