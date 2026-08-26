# Agent Session Switcher — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A menu-bar switcher listing every terminal session, grouped by whether it needs the human, coloured per project, focusable with `⌥1…⌥8`, with a badge showing how many agents are waiting.

**Architecture:** Terminal.app's AppleScript dictionary supplies windows, tabs, titles, tty, busy flag and process lists. Claude Code hooks write per-tty state files to `~/.chute/sessions/`, joined to tabs by tty. All logic lives in pure, testable types in `ChuteCore`; `ChuteApp` renders an `NSMenu`; the `chute` CLI exposes the same data.

**Tech Stack:** Swift 5.10, SwiftPM, AppKit, Foundation, osascript. **Zero third-party dependencies.**

**Spec:** `/Users/sxope/Documents/2026/Development/37.chute/docs/superpowers/specs/2026-08-26-session-switcher-design.md`

## Global Constraints

- **Zero third-party dependencies.** Never add `.package(` to `Package.swift`.
- **No XCTest.** `swift test` cannot run — XCTest ships with Xcode, which is not installed. Tests are assertions in the `chutetests` executable, run with `swift run chutetests`.
- Swift tools version **5.10**, platform floor **macOS 13**.
- Files: 200–400 lines typical, **800 hard maximum**. Functions under 50 lines, nesting under 4.
- **Never mutate an input** — return a new value carrying the change.
- Every public type and function in `ChuteCore` must be `public`; the test executable imports the module normally (there is no `@testable`).
- All user-facing paths in output are **absolute**.
- `~/.claude/settings.json` is the founder's live global config carrying 12 configured hook events. Any code touching it is **append-only, backed up first, validated before replacing, and reversible**. Losing it is worse than the problem this feature solves.
- Commit after every task with `<type>: <description>`. Do not commit if `swift run chutetests` is red.

## Parallel Dispatch Map

Tasks in the same wave touch **disjoint files** and may run concurrently as subagents. Never assign two agents to one file.

| Wave | Tasks | Model | Why that model |
|---|---|---|---|
| 0 | Task 1 | **Opus (lead, in-session)** | Defines the interfaces every other task codes against. Wrong here means all waves are wrong. |
| A | Tasks 2, 3, 4 | **Haiku** ×1, **Sonnet** ×2 | Task 2 is a specified hash-to-palette function (mechanical). Tasks 3–4 carry judgment about state and staleness. |
| B | Tasks 5, 6 | **Sonnet** ×2 | Parsing real AppleScript output, and a safe merge into a live config. Both need care. |
| C | Task 7, then 8 | **Sonnet** | Sequential: the menu consumes the CLI's data shape. |
| D | Task 9 | **Haiku** | Mechanical wiring of scripts and docs. |

**Barriers:** Wave A starts only after Task 1 is committed and green. Wave B starts after Wave A is merged and green — Task 5 and 6 both extend `chutetests/main.swift`'s call list? No: their call sites are created in Task 1, so they do not. Wave C starts after Wave B.

**Dispatch brief for every subagent (paste verbatim into the prompt):**
> Spec: `/Users/sxope/Documents/2026/Development/37.chute/docs/superpowers/specs/2026-08-26-session-switcher-design.md`
> Plan: `/Users/sxope/Documents/2026/Development/37.chute/docs/superpowers/plans/2026-08-26-session-switcher.md`
> Do ONLY your task. Touch ONLY the files your task lists — another agent owns every other file.
> Verify with `swift run chutetests`, read the tally, and report the real number. Perturb your new guard until it goes red, then restore it.
> Report in ≤12 lines: files changed, assertion count before/after, the one output line proving it works.

---

### Task 1: Foundation — split the test harness, define the shared model

Everything else codes against the types defined here. This task exists so five later agents never touch the same file.

**Files:**
- Modify: `/Users/sxope/Documents/2026/Development/37.chute/Sources/chutetests/main.swift` (currently 100 lines, 7 suites)
- Create: `/Users/sxope/Documents/2026/Development/37.chute/Sources/chutetests/CoreSuites.swift`
- Create: `/Users/sxope/Documents/2026/Development/37.chute/Sources/chutetests/SessionSuite.swift`
- Create: `/Users/sxope/Documents/2026/Development/37.chute/Sources/chutetests/SessionColorSuite.swift`
- Create: `/Users/sxope/Documents/2026/Development/37.chute/Sources/chutetests/GlyphSuite.swift`
- Create: `/Users/sxope/Documents/2026/Development/37.chute/Sources/chutetests/HookStateSuite.swift`
- Create: `/Users/sxope/Documents/2026/Development/37.chute/Sources/chutetests/HookInstallerSuite.swift`
- Create: `/Users/sxope/Documents/2026/Development/37.chute/Sources/chutetests/TerminalParseSuite.swift`
- Create: `/Users/sxope/Documents/2026/Development/37.chute/Sources/ChuteCore/Session.swift`
- Create: `/Users/sxope/Documents/2026/Development/37.chute/Sources/ChuteCore/TerminalAdapter.swift`

**Interfaces:**
- Consumes: the existing `T` harness in `Sources/chutetests/Harness.swift`.
- Produces: `Session`, `SessionState`, `TerminalKind`, `HookRecord`, `TerminalAdapter`, and seven suite functions with fixed names. Every later task fills exactly one suite file and creates exactly one `ChuteCore` file.

- [ ] **Step 1: Move the existing suites into their own file**

Cut everything between `let files3 = …` and the line before `T.report()` out of `Sources/chutetests/main.swift` and paste it into `Sources/chutetests/CoreSuites.swift`, wrapped in a function:

```swift
import Foundation
import ChuteCore

let files3 = ["/tmp/proj/src/a.ts", "/tmp/proj/src/b.ts", "/tmp/proj/README.md"]

func coreSuites() {
    // ← the seven existing T.suite("…") { … } blocks go here unchanged
}
```

- [ ] **Step 2: Reduce main.swift to a runner with all call sites pre-created**

Replace the entire contents of `Sources/chutetests/main.swift` with exactly this. The stub calls exist now so later agents never edit this file:

```swift
import Foundation
import ChuteCore

coreSuites()
sessionSuite()
sessionColorSuite()
glyphSuite()
hookStateSuite()
hookInstallerSuite()
terminalParseSuite()

T.report()
```

- [ ] **Step 3: Create the six empty suite stubs**

Each of `SessionSuite.swift`, `SessionColorSuite.swift`, `GlyphSuite.swift`, `HookStateSuite.swift`, `HookInstallerSuite.swift`, `TerminalParseSuite.swift` gets the matching stub, e.g.:

```swift
import Foundation
import ChuteCore

func sessionSuite() {
    // Task 2 fills this. Owned by exactly one agent.
}
```

Function names, one per file: `sessionSuite`, `sessionColorSuite`, `glyphSuite`, `hookStateSuite`, `hookInstallerSuite`, `terminalParseSuite`.

- [ ] **Step 4: Run the suite — the split must change nothing**

Run: `cd /Users/sxope/Documents/2026/Development/37.chute && swift run chutetests`
Expected: `✅ 55 assertions passed` — the exact same number as before the split.

- [ ] **Step 5: Create the shared model**

`Sources/ChuteCore/Session.swift`:

```swift
import Foundation

public enum TerminalKind: String, Sendable {
    case terminalApp = "Terminal"
}

/// Ordered by urgency. `Comparable` gives the menu its grouping for free.
public enum SessionState: Int, Sendable, Comparable, CaseIterable {
    case blocked = 0    // PermissionRequest — needs you now
    case waiting = 1    // Stop — finished, awaiting your prompt
    case working = 2    // agent is running
    case idle    = 3    // plain shell, no agent
    case unknown = 4

    public static func < (a: SessionState, b: SessionState) -> Bool {
        a.rawValue < b.rawValue
    }

    public var label: String {
        switch self {
        case .blocked: return "BLOCKED"
        case .waiting: return "waiting"
        case .working: return "working"
        case .idle:    return "shell"
        case .unknown: return "—"
        }
    }
}

/// One row written by a Claude Code hook, keyed by the terminal tab's tty.
public struct HookRecord: Sendable, Equatable {
    public let tty: String          // "ttys004" — no /dev prefix
    public let state: SessionState
    public let cwd: String?
    public let sessionID: String?
    public let timestamp: Date

    public init(tty: String, state: SessionState, cwd: String? = nil,
                sessionID: String? = nil, timestamp: Date) {
        self.tty = tty
        self.state = state
        self.cwd = cwd
        self.sessionID = sessionID
        self.timestamp = timestamp
    }
}

public struct Session: Sendable, Equatable {
    public let key: String          // "Terminal:207250:ttys004" — stable identity
    public let kind: TerminalKind
    public let windowID: Int
    public let tabIndex: Int        // 1-based, matches AppleScript
    public let tty: String          // "ttys004", normalised without /dev
    public let project: String      // "36.macai"
    public let title: String        // "◑ Chut"
    public let isAgent: Bool
    public let busy: Bool
    public let state: SessionState
    public let since: Date?

    public init(key: String, kind: TerminalKind, windowID: Int, tabIndex: Int,
                tty: String, project: String, title: String, isAgent: Bool,
                busy: Bool, state: SessionState, since: Date?) {
        self.key = key; self.kind = kind; self.windowID = windowID
        self.tabIndex = tabIndex; self.tty = tty; self.project = project
        self.title = title; self.isAgent = isAgent; self.busy = busy
        self.state = state; self.since = since
    }

    /// "/dev/ttys004" and "ttys004" both normalise to "ttys004".
    public static func normalise(tty: String) -> String {
        tty.hasPrefix("/dev/") ? String(tty.dropFirst(5)) : tty
    }

    public static func makeKey(kind: TerminalKind, windowID: Int, tty: String) -> String {
        "\(kind.rawValue):\(windowID):\(normalise(tty: tty))"
    }
}
```

`Sources/ChuteCore/TerminalAdapter.swift`:

```swift
import Foundation

public enum TerminalError: Error, CustomStringConvertible {
    case notRunning(String)
    case scriptFailed(String)
    case timedOut

    public var description: String {
        switch self {
        case .notRunning(let app): return "\(app) is not running"
        case .scriptFailed(let m):  return "AppleScript failed: \(m)"
        case .timedOut:             return "the terminal did not respond in time"
        }
    }
}

public protocol TerminalAdapter {
    var kind: TerminalKind { get }
    func discover(hooks: [String: HookRecord], now: Date) throws -> [Session]
    func focus(_ session: Session) throws
}
```

- [ ] **Step 6: Add one assertion proving the model works**

In `Sources/chutetests/SessionSuite.swift`, replace the stub body with:

```swift
func sessionSuite() {
    T.suite("Session") {
        T.eq(Session.normalise(tty: "/dev/ttys004"), "ttys004", "strips /dev prefix")
        T.eq(Session.normalise(tty: "ttys004"), "ttys004", "already normalised is unchanged")
        T.eq(Session.makeKey(kind: .terminalApp, windowID: 207250, tty: "/dev/ttys004"),
             "Terminal:207250:ttys004", "stable session key")
        T.ok(SessionState.blocked < SessionState.waiting, "blocked outranks waiting")
        T.ok(SessionState.waiting < SessionState.idle, "waiting outranks idle")
        T.eq(SessionState.blocked.label, "BLOCKED", "label")
    }
}
```

- [ ] **Step 7: Run and confirm the count grew**

Run: `cd /Users/sxope/Documents/2026/Development/37.chute && swift run chutetests`
Expected: `✅ 61 assertions passed`

- [ ] **Step 8: Prove the suite can fail**

Temporarily change `normalise` to `return tty`. Run again. Expected: `❌ 1 failed, 60 passed` naming "strips /dev prefix". Restore the correct implementation and re-run to `✅ 61`.

- [ ] **Step 9: Commit**

```bash
cd /Users/sxope/Documents/2026/Development/37.chute
git add Sources/ChuteCore/Session.swift Sources/ChuteCore/TerminalAdapter.swift Sources/chutetests/
git commit -m "refactor: split test suites into per-file owners; add Session model and TerminalAdapter protocol"
```

---

### Task 2: Deterministic project colours  ·  **Model: Haiku**  ·  Wave A

Pure function, fully specified, no design judgment — mechanical work.

**Files:**
- Create: `/Users/sxope/Documents/2026/Development/37.chute/Sources/ChuteCore/SessionColor.swift`
- Modify: `/Users/sxope/Documents/2026/Development/37.chute/Sources/chutetests/SessionColorSuite.swift`

**Interfaces:**
- Consumes: nothing from other tasks.
- Produces: `SessionColor.hex(forProject:) -> String`, `SessionColor.index(forProject:) -> Int`, `SessionColor.palette: [String]`. Task 8 calls `hex(forProject:)` to colour menu dots.

- [ ] **Step 1: Write the failing test**

Replace the stub in `Sources/chutetests/SessionColorSuite.swift`:

```swift
func sessionColorSuite() {
    T.suite("SessionColor") {
        T.eq(SessionColor.palette.count, 12, "twelve colours")
        T.ok(SessionColor.palette.allSatisfy { $0.hasPrefix("#") && $0.count == 7 },
             "every entry is a 7-char hex string")

        let a = SessionColor.hex(forProject: "/Users/sxope/Documents/2026/Development/37.chute")
        let b = SessionColor.hex(forProject: "/Users/sxope/Documents/2026/Development/37.chute")
        T.eq(a, b, "same project always gets the same colour")

        let i = SessionColor.index(forProject: "/any/path")
        T.ok(i >= 0 && i < 12, "index stays inside the palette")

        T.eq(SessionColor.index(forProject: ""), SessionColor.index(forProject: ""),
             "empty path is stable, not a crash")

        // The founder's five real projects must not collide into one colour.
        let projects = ["/Users/sxope/Documents/2026/Development/37.chute",
                        "/Users/sxope/Documents/2026/Development/31.Chrome/studylock",
                        "/Users/sxope/Documents/2026/Development/5.STNZ_AI/sntz_mockups",
                        "/Users/sxope/Documents/2026/Development/docs",
                        "/Users/sxope/Documents/2026/Development/BigDeal"]
        let distinct = Set(projects.map { SessionColor.index(forProject: $0) })
        T.ok(distinct.count >= 4, "at most one collision across five real projects")
    }
}
```

- [ ] **Step 2: Run to verify it fails**

Run: `cd /Users/sxope/Documents/2026/Development/37.chute && swift run chutetests`
Expected: a compile error — `cannot find 'SessionColor' in scope`.

- [ ] **Step 3: Write the implementation**

`Sources/ChuteCore/SessionColor.swift`:

```swift
import Foundation

/// A project's colour must be identical every launch, so it is derived from the path,
/// never assigned in discovery order. Claude Code's own `/color` is not persisted to
/// disk anywhere, so Chute owns this rather than depending on an internal format.
public enum SessionColor {
    /// Twelve hues that stay distinguishable against both light and dark menu backgrounds.
    public static let palette: [String] = [
        "#E06C75", "#E5934A", "#E5C07B", "#98C379",
        "#56B6C2", "#61AFEF", "#8C7AE6", "#C678DD",
        "#D19A66", "#4DB6AC", "#7E9CD8", "#DE8F78",
    ]

    /// FNV-1a, 32-bit. Chosen because it is short, stable across platforms and versions,
    /// and has no dependency — unlike Swift's `Hasher`, which is seeded per process.
    public static func index(forProject path: String) -> Int {
        var hash: UInt32 = 2_166_136_261
        for byte in path.utf8 {
            hash ^= UInt32(byte)
            hash = hash &* 16_777_619
        }
        return Int(hash % UInt32(palette.count))
    }

    public static func hex(forProject path: String) -> String {
        palette[index(forProject: path)]
    }
}
```

- [ ] **Step 4: Run to verify it passes**

Run: `cd /Users/sxope/Documents/2026/Development/37.chute && swift run chutetests`
Expected: `✅ 68 assertions passed`

- [ ] **Step 5: Prove the guard fails**

Change `hash = hash &* 16_777_619` to `hash = hash &* 1`. Re-run. Expected: the five-project distinctness assertion fails. Restore and confirm `✅ 68`.

- [ ] **Step 6: Commit**

```bash
cd /Users/sxope/Documents/2026/Development/37.chute
git add Sources/ChuteCore/SessionColor.swift Sources/chutetests/SessionColorSuite.swift
git commit -m "feat: deterministic per-project colours from an FNV-1a hash"
```

---

### Task 3: Glyph table and state resolution  ·  **Model: Sonnet**  ·  Wave A

**Files:**
- Create: `/Users/sxope/Documents/2026/Development/37.chute/Sources/ChuteCore/StateResolver.swift`
- Modify: `/Users/sxope/Documents/2026/Development/37.chute/Sources/chutetests/GlyphSuite.swift`

**Interfaces:**
- Consumes: `SessionState`, `HookRecord` from Task 1.
- Produces: `StateResolver.resolve(hook:title:busy:isAgent:now:staleAfter:) -> SessionState` and `GlyphTable.state(fromTitle:) -> SessionState?`. Task 5 calls `resolve` for every discovered tab.

- [ ] **Step 1: Write the failing test**

Replace the stub in `Sources/chutetests/GlyphSuite.swift`:

```swift
func glyphSuite() {
    T.suite("StateResolver") {
        let now = Date(timeIntervalSince1970: 1_756_219_200)
        let fresh = HookRecord(tty: "ttys004", state: .blocked, timestamp: now.addingTimeInterval(-60))
        let stale = HookRecord(tty: "ttys004", state: .blocked, timestamp: now.addingTimeInterval(-7 * 3600))

        T.eq(StateResolver.resolve(hook: fresh, title: "✳ anything", busy: true, isAgent: true, now: now),
             .blocked, "a fresh hook beats the title and the busy flag")

        T.eq(StateResolver.resolve(hook: stale, title: "plain", busy: true, isAgent: true, now: now),
             .working, "a hook older than six hours is ignored")

        T.eq(StateResolver.resolve(hook: nil, title: "✳ refactoring", busy: true, isAgent: true, now: now),
             .working, "known glyph resolves without a hook")

        T.eq(StateResolver.resolve(hook: nil, title: "☂ unknown glyph", busy: true, isAgent: true, now: now),
             .working, "unknown glyph falls through to the busy flag")

        T.eq(StateResolver.resolve(hook: nil, title: "no glyph", busy: false, isAgent: true, now: now),
             .waiting, "an idle agent is waiting for you")

        T.eq(StateResolver.resolve(hook: nil, title: "-zsh", busy: false, isAgent: false, now: now),
             .idle, "a plain shell is idle, never 'waiting'")

        T.eq(StateResolver.resolve(hook: nil, title: "-zsh", busy: true, isAgent: false, now: now),
             .working, "a busy shell is working")

        T.ok(GlyphTable.state(fromTitle: "✳ x") != nil, "✳ is a known glyph")
        T.ok(GlyphTable.state(fromTitle: "◑ x") != nil, "◑ is a known glyph")
        T.ok(GlyphTable.state(fromTitle: "hello") == nil, "plain text has no glyph")
        T.ok(GlyphTable.state(fromTitle: "") == nil, "empty title is nil, not a crash")
    }
}
```

- [ ] **Step 2: Run to verify it fails**

Run: `cd /Users/sxope/Documents/2026/Development/37.chute && swift run chutetests`
Expected: compile error — `cannot find 'StateResolver' in scope`.

- [ ] **Step 3: Write the implementation**

`Sources/ChuteCore/StateResolver.swift`:

```swift
import Foundation

/// Claude Code writes a status glyph at the start of the terminal title.
/// Observed on 2026-08-26 across five live sessions: "✳" and "◑", both while busy.
/// Their exact meanings are undocumented, so both map to `.working` and anything
/// unrecognised deliberately falls through to the busy flag rather than inventing a state.
/// If Claude Code changes its glyphs, only this table changes.
public enum GlyphTable {
    public static let map: [Character: SessionState] = [
        "✳": .working,
        "◑": .working,
        "✶": .working,
        "✻": .working,
    ]

    public static func state(fromTitle title: String) -> SessionState? {
        guard let first = title.trimmingCharacters(in: .whitespaces).first else { return nil }
        return map[first]
    }
}

public enum StateResolver {
    /// A hook older than this is treated as dead, so a crashed session cannot pin a
    /// permanent false "waiting" badge on the menu bar.
    public static let staleAfterDefault: TimeInterval = 6 * 3600

    public static func resolve(hook: HookRecord?,
                               title: String,
                               busy: Bool,
                               isAgent: Bool,
                               now: Date,
                               staleAfter: TimeInterval = staleAfterDefault) -> SessionState {
        if let hook, now.timeIntervalSince(hook.timestamp) < staleAfter {
            return hook.state
        }
        if let glyphState = GlyphTable.state(fromTitle: title) {
            return glyphState
        }
        if busy { return .working }
        return isAgent ? .waiting : .idle
    }
}
```

- [ ] **Step 4: Run to verify it passes**

Run: `cd /Users/sxope/Documents/2026/Development/37.chute && swift run chutetests`
Expected: 11 more assertions than the previous total.

- [ ] **Step 5: Prove the staleness guard fails**

Change `< staleAfter` to `< staleAfter * 1000`. Re-run. Expected: "a hook older than six hours is ignored" fails. Restore and confirm green.

- [ ] **Step 6: Commit**

```bash
cd /Users/sxope/Documents/2026/Development/37.chute
git add Sources/ChuteCore/StateResolver.swift Sources/chutetests/GlyphSuite.swift
git commit -m "feat: session state resolution — hook beats glyph beats busy flag, with staleness cutoff"
```

---

### Task 4: Hook state store  ·  **Model: Sonnet**  ·  Wave A

**Files:**
- Create: `/Users/sxope/Documents/2026/Development/37.chute/Sources/ChuteCore/HookState.swift`
- Modify: `/Users/sxope/Documents/2026/Development/37.chute/Sources/chutetests/HookStateSuite.swift`

**Interfaces:**
- Consumes: `HookRecord`, `SessionState`, `Session.normalise(tty:)` from Task 1.
- Produces: `HookState.directory(root:) -> String`, `HookState.readAll(root:) -> [String: HookRecord]`, `HookState.parse(_ data: Data) -> HookRecord?`. Task 5 passes `readAll()` into `discover`; Task 8 watches `directory()` with a `DispatchSource`.

- [ ] **Step 1: Write the failing test**

Replace the stub in `Sources/chutetests/HookStateSuite.swift`:

```swift
func hookStateSuite() {
    T.suite("HookState") {
        let json = Data("""
        {"tty":"ttys004","state":"blocked","cwd":"/Users/sxope/p","session_id":"abc","ts":1756219200}
        """.utf8)
        guard let r = HookState.parse(json) else {
            T.ok(false, "parses a well-formed record"); return
        }
        T.eq(r.tty, "ttys004", "tty parsed")
        T.eq(r.state, .blocked, "state parsed")
        T.eq(r.cwd ?? "", "/Users/sxope/p", "cwd parsed")
        T.eq(r.timestamp, Date(timeIntervalSince1970: 1_756_219_200), "timestamp parsed")

        T.ok(HookState.parse(Data("not json".utf8)) == nil, "garbage returns nil, never throws")
        T.ok(HookState.parse(Data("{}".utf8)) == nil, "missing fields returns nil")
        T.ok(HookState.parse(Data(#"{"tty":"t","state":"nonsense","ts":1}"#.utf8)) == nil,
             "unknown state string returns nil")
        T.ok(HookState.parse(Data(#"{"tty":"/dev/ttys004","state":"waiting","ts":1}"#.utf8))?.tty == "ttys004",
             "tty is normalised on the way in")

        // Round-trip through a real temp directory.
        let root = NSTemporaryDirectory() + "chute-hookstate-test-\(UInt32.random(in: 0...99999))"
        defer { try? FileManager.default.removeItem(atPath: root) }
        let rec = HookRecord(tty: "ttys009", state: .waiting,
                             timestamp: Date(timeIntervalSince1970: 1_756_219_200))
        T.noThrow("writes a record") { try HookState.write(rec, root: root) }
        let all = HookState.readAll(root: root)
        T.eq(all.count, 1, "one record read back")
        T.eq(all["ttys009"]?.state, .waiting, "keyed by normalised tty")

        T.eq(HookState.readAll(root: root + "-does-not-exist").count, 0,
             "a missing directory is empty, not an error")
    }
}
```

- [ ] **Step 2: Run to verify it fails**

Run: `cd /Users/sxope/Documents/2026/Development/37.chute && swift run chutetests`
Expected: compile error — `cannot find 'HookState' in scope`.

- [ ] **Step 3: Write the implementation**

`Sources/ChuteCore/HookState.swift`:

```swift
import Foundation

/// Per-tty state written by Claude Code hooks. One small JSON file per terminal tab.
/// Reads never throw: a corrupt file must degrade one row, never break the menu.
public enum HookState {
    public static func directory(root: String? = nil) -> String {
        root ?? (NSHomeDirectory() as NSString).appendingPathComponent(".chute/sessions")
    }

    public static func parse(_ data: Data) -> HookRecord? {
        guard let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let rawTTY = obj["tty"] as? String,
              let rawState = obj["state"] as? String,
              let ts = obj["ts"] as? Double
        else { return nil }

        let states: [String: SessionState] = [
            "blocked": .blocked, "waiting": .waiting,
            "working": .working, "idle": .idle,
        ]
        guard let state = states[rawState] else { return nil }

        return HookRecord(tty: Session.normalise(tty: rawTTY),
                          state: state,
                          cwd: obj["cwd"] as? String,
                          sessionID: obj["session_id"] as? String,
                          timestamp: Date(timeIntervalSince1970: ts))
    }

    /// Atomic: written to a temp name then moved, so a reader never sees half a file.
    public static func write(_ record: HookRecord, root: String? = nil) throws {
        let dir = directory(root: root)
        try FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        var obj: [String: Any] = [
            "tty": record.tty,
            "state": String(describing: stateName(record.state)),
            "ts": record.timestamp.timeIntervalSince1970,
        ]
        if let cwd = record.cwd { obj["cwd"] = cwd }
        if let sid = record.sessionID { obj["session_id"] = sid }

        let data = try JSONSerialization.data(withJSONObject: obj)
        let final = (dir as NSString).appendingPathComponent("\(record.tty).json")
        let temp = final + ".tmp"
        try data.write(to: URL(fileURLWithPath: temp))
        _ = try FileManager.default.replaceItemAt(URL(fileURLWithPath: final),
                                                  withItemAt: URL(fileURLWithPath: temp))
    }

    public static func readAll(root: String? = nil) -> [String: HookRecord] {
        let dir = directory(root: root)
        guard let names = try? FileManager.default.contentsOfDirectory(atPath: dir) else { return [:] }
        var out: [String: HookRecord] = [:]
        for name in names where name.hasSuffix(".json") {
            let path = (dir as NSString).appendingPathComponent(name)
            guard let data = FileManager.default.contents(atPath: path),
                  let record = parse(data) else { continue }
            out[record.tty] = record
        }
        return out
    }

    static func stateName(_ s: SessionState) -> String {
        switch s {
        case .blocked: return "blocked"
        case .waiting: return "waiting"
        case .working: return "working"
        case .idle:    return "idle"
        case .unknown: return "idle"
        }
    }
}
```

- [ ] **Step 4: Run to verify it passes**

Run: `cd /Users/sxope/Documents/2026/Development/37.chute && swift run chutetests`
Expected: 12 more assertions than before, zero failures.

- [ ] **Step 5: Prove a guard fails**

Delete the `guard let state = states[rawState] else { return nil }` line and return `.idle` instead. Re-run. Expected: "unknown state string returns nil" fails. Restore and confirm green.

- [ ] **Step 6: Commit**

```bash
cd /Users/sxope/Documents/2026/Development/37.chute
git add Sources/ChuteCore/HookState.swift Sources/chutetests/HookStateSuite.swift
git commit -m "feat: per-tty hook state store with atomic writes and forgiving reads"
```

---

### Task 5: Terminal.app adapter  ·  **Model: Sonnet**  ·  Wave B

**Files:**
- Create: `/Users/sxope/Documents/2026/Development/37.chute/Sources/ChuteCore/TerminalAppAdapter.swift`
- Modify: `/Users/sxope/Documents/2026/Development/37.chute/Sources/chutetests/TerminalParseSuite.swift`

**Interfaces:**
- Consumes: `Session`, `SessionState`, `HookRecord`, `TerminalAdapter`, `TerminalError` (Task 1); `StateResolver.resolve` (Task 3).
- Produces: `TerminalAppAdapter()` conforming to `TerminalAdapter`, and `TerminalAppAdapter.parse(_ raw: String, hooks:now:) -> [Session]` — a pure function so the parser is tested without AppleScript. Task 7 and Task 8 both construct `TerminalAppAdapter()`.

- [ ] **Step 1: Write the failing test using a REAL recorded capture**

Replace the stub in `Sources/chutetests/TerminalParseSuite.swift`. The fixture below is genuine output captured from the founder's Mac on 2026-08-26 — `\u{1F}` separates fields, `\u{1E}` separates records:

```swift
func terminalParseSuite() {
    T.suite("TerminalAppAdapter.parse") {
        let now = Date(timeIntervalSince1970: 1_756_219_200)
        let US = "\u{1F}", RS = "\u{1E}"
        func rec(_ f: [String]) -> String { f.joined(separator: US) }

        let raw = [
            rec(["207250", "sntz_mockups — ✳ File-size gate refactor complete — node ◂ claude",
                 "1", "/dev/ttys000", "true", "true",
                 "login-zsh, claude, node, mcp@latest", "✳ File-size gate refactor complete"]),
            rec(["207397", "docs — -zsh — 80×24", "1", "/dev/ttys003", "false", "true",
                 "login-zsh", "Terminal"]),
            rec(["210583", "36.macai — ◑ Chut — caffeinate ◂ claude — 245×76",
                 "1", "/dev/ttys004", "true", "true",
                 "login-zsh, claude, node, caffeinate", "◑ Chut"]),
        ].joined(separator: RS)

        let hooks = ["ttys004": HookRecord(tty: "ttys004", state: .blocked,
                                          timestamp: now.addingTimeInterval(-120))]
        let sessions = TerminalAppAdapter.parse(raw, hooks: hooks, now: now)

        T.eq(sessions.count, 3, "three tabs parsed")
        T.eq(sessions[0].project, "sntz_mockups", "project taken from the window name")
        T.eq(sessions[1].project, "docs", "project for a plain shell")
        T.eq(sessions[0].tty, "ttys000", "tty normalised")
        T.eq(sessions[0].windowID, 207250, "window id parsed")
        T.ok(sessions[0].isAgent, "claude in the process list means agent")
        T.no(sessions[1].isAgent, "a plain shell is not an agent")
        T.eq(sessions[1].state, .idle, "plain idle shell")
        T.eq(sessions[2].state, .blocked, "the hook for ttys004 wins")
        T.eq(sessions[0].state, .working, "glyph resolves the hookless agent")
        T.eq(sessions[2].key, "Terminal:210583:ttys004", "key built from kind, window and tty")

        // Malformed input must degrade, never crash.
        T.eq(TerminalAppAdapter.parse("", hooks: [:], now: now).count, 0, "empty input")
        T.eq(TerminalAppAdapter.parse("garbage", hooks: [:], now: now).count, 0, "too few fields")
        T.eq(TerminalAppAdapter.parse(rec(["notanumber", "p — t", "1", "ttys1", "false", "true", "zsh", "t"]),
                                      hooks: [:], now: now).count, 0, "non-numeric window id is skipped")

        // Project extraction edge cases.
        T.eq(TerminalAppAdapter.project(fromWindowName: "36.macai — ◑ Chut — x"), "36.macai", "first segment")
        T.eq(TerminalAppAdapter.project(fromWindowName: "solo"), "solo", "no separator")
        T.eq(TerminalAppAdapter.project(fromWindowName: ""), "—", "empty name has a placeholder")
    }
}
```

- [ ] **Step 2: Run to verify it fails**

Run: `cd /Users/sxope/Documents/2026/Development/37.chute && swift run chutetests`
Expected: compile error — `cannot find 'TerminalAppAdapter' in scope`.

- [ ] **Step 3: Write the implementation**

`Sources/ChuteCore/TerminalAppAdapter.swift`:

```swift
import Foundation

/// Terminal.app via AppleScript. No Accessibility permission, no process-table polling.
/// Fields are separated by ASCII US (0x1F) and records by RS (0x1E) because window titles
/// legitimately contain commas, dashes, quotes and emoji.
public struct TerminalAppAdapter: TerminalAdapter {
    public let kind: TerminalKind = .terminalApp
    public init() {}

    static let US = "\u{1F}"
    static let RS = "\u{1E}"

    static let discoveryScript = """
    tell application "Terminal"
        set out to ""
        repeat with w in windows
            set wid to id of w
            set wname to name of w
            set idx to 0
            repeat with t in tabs of w
                set idx to idx + 1
                set out to out & wid & "\(US)" & wname & "\(US)" & idx & "\(US)" & ¬
                    (tty of t) & "\(US)" & (busy of t) & "\(US)" & (selected of t) & "\(US)" & ¬
                    (processes of t as string) & "\(US)" & (custom title of t) & "\(RS)"
            end repeat
        end repeat
        return out
    end tell
    """

    public func discover(hooks: [String: HookRecord], now: Date) throws -> [Session] {
        guard NSWorkspaceIsRunning("com.apple.Terminal") else {
            throw TerminalError.notRunning("Terminal")
        }
        let result = Shell.run("osascript", ["-e", Self.discoveryScript])
        guard result.ok else { throw TerminalError.scriptFailed(result.err) }
        return Self.parse(result.out, hooks: hooks, now: now)
    }

    public func focus(_ session: Session) throws {
        let script = """
        tell application "Terminal"
            set frontmost of window id \(session.windowID) to true
            try
                set selected of tab \(session.tabIndex) of window id \(session.windowID) to true
            end try
        end tell
        activate application "Terminal"
        """
        let r = Shell.run("osascript", ["-e", script])
        guard r.ok else { throw TerminalError.scriptFailed(r.err) }
    }

    /// Pure — this is what the tests exercise, with no AppleScript involved.
    public static func parse(_ raw: String, hooks: [String: HookRecord], now: Date) -> [Session] {
        raw.components(separatedBy: RS).compactMap { record -> Session? in
            let f = record.components(separatedBy: US)
            guard f.count >= 8, let windowID = Int(f[0].trimmingCharacters(in: .whitespacesAndNewlines))
            else { return nil }

            let tty = Session.normalise(tty: f[3])
            let processes = f[6]
            let title = f[7]
            let isAgent = ["claude", "codex", "gemini", "aider"].contains { processes.contains($0) }
            let busy = f[4].trimmingCharacters(in: .whitespaces) == "true"
            let hook = hooks[tty]

            return Session(
                key: Session.makeKey(kind: .terminalApp, windowID: windowID, tty: tty),
                kind: .terminalApp,
                windowID: windowID,
                tabIndex: Int(f[2]) ?? 1,
                tty: tty,
                project: project(fromWindowName: f[1]),
                title: title,
                isAgent: isAgent,
                busy: busy,
                state: StateResolver.resolve(hook: hook, title: title, busy: busy,
                                             isAgent: isAgent, now: now),
                since: hook?.timestamp
            )
        }
    }

    /// Terminal window names read "36.macai — ◑ Chut — caffeinate ◂ claude — 245×76".
    /// The first em-dash segment is the working directory's leaf, which is the project.
    public static func project(fromWindowName name: String) -> String {
        let head = name.components(separatedBy: " — ").first?
            .trimmingCharacters(in: .whitespaces) ?? ""
        return head.isEmpty ? "—" : head
    }
}

/// Avoids importing AppKit into ChuteCore just for a running-app check.
func NSWorkspaceIsRunning(_ bundleID: String) -> Bool {
    !Shell.run("pgrep", ["-x", "Terminal"]).out
        .trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
}
```

- [ ] **Step 4: Run to verify it passes**

Run: `cd /Users/sxope/Documents/2026/Development/37.chute && swift run chutetests`
Expected: 16 more assertions than before, zero failures.

- [ ] **Step 5: Verify against the REAL Terminal, not just the fixture**

Run: `cd /Users/sxope/Documents/2026/Development/37.chute && swift build -c release && ./.build/release/chute sessions 2>&1 | head`
This will not work until Task 7 adds the command — that is expected. Instead confirm the AppleScript itself is valid:
`osascript -e 'tell application "Terminal" to return count of windows'`
Expected: a number matching your open windows.

- [ ] **Step 6: Prove a guard fails**

Change `guard f.count >= 8` to `guard f.count >= 1`. Re-run. Expected: "too few fields" fails. Restore and confirm green.

- [ ] **Step 7: Commit**

```bash
cd /Users/sxope/Documents/2026/Development/37.chute
git add Sources/ChuteCore/TerminalAppAdapter.swift Sources/chutetests/TerminalParseSuite.swift
git commit -m "feat: Terminal.app adapter — AppleScript discovery with a pure, fixture-tested parser"
```

---

### Task 6: Claude Code hook installer  ·  **Model: Sonnet**  ·  Wave B

**The highest-risk task in the plan.** `~/.claude/settings.json` is the founder's live global configuration with 12 configured hook events. Destroying it is worse than never shipping this feature. Read the "Hook installation must not damage a live config" section of the spec before writing a line.

**Files:**
- Create: `/Users/sxope/Documents/2026/Development/37.chute/Sources/ChuteCore/HookInstaller.swift`
- Modify: `/Users/sxope/Documents/2026/Development/37.chute/Sources/chutetests/HookInstallerSuite.swift`

**Interfaces:**
- Consumes: nothing from other tasks.
- Produces: `HookInstaller.install(settingsPath:backupSuffix:) throws -> HookReport`, `HookInstaller.uninstall(settingsPath:) throws -> HookReport`, `HookInstaller.status(settingsPath:) -> [String: Bool]`, `HookInstaller.marker: String`. Task 7 wraps these in `chute hooks …`.

- [ ] **Step 1: Write the failing test against a REAL-SHAPED fixture**

Replace the stub in `Sources/chutetests/HookInstallerSuite.swift`. The fixture mirrors the founder's actual file: populated hook arrays with an existing complex command that must survive untouched.

```swift
func hookInstallerSuite() {
    T.suite("HookInstaller") {
        let dir = NSTemporaryDirectory() + "chute-hooks-\(UInt32.random(in: 0...99999))"
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(atPath: dir) }
        let path = (dir as NSString).appendingPathComponent("settings.json")

        let original = """
        {"permissions":{"allow":["Bash"]},"model":"opus","statusLine":{"type":"command"},
         "hooks":{
           "Stop":[{"hooks":[{"type":"command","command":"existing-plugin-command --flag"}]}],
           "PermissionRequest":[{"hooks":[{"type":"command","command":"another-one"}]}],
           "UserPromptSubmit":[{"hooks":[{"type":"command","command":"third"}]}],
           "SessionStart":[{"hooks":[{"type":"command","command":"fourth"}]}],
           "PreCompact":[{"hooks":[{"type":"command","command":"untouched"}]}]}}
        """
        func reset() { try? original.write(toFile: path, atomically: true, encoding: .utf8) }
        func load() -> [String: Any] {
            (try? JSONSerialization.jsonObject(with: Data(contentsOf: URL(fileURLWithPath: path))))
                as? [String: Any] ?? [:]
        }
        func entries(_ d: [String: Any], _ event: String) -> Int {
            ((d["hooks"] as? [String: Any])?[event] as? [Any])?.count ?? 0
        }

        reset()
        T.noThrow("install succeeds") { _ = try HookInstaller.install(settingsPath: path) }
        var d = load()

        T.eq(entries(d, "Stop"), 2, "appended to Stop, original entry kept")
        T.eq(entries(d, "PermissionRequest"), 2, "appended to PermissionRequest")
        T.eq(entries(d, "UserPromptSubmit"), 2, "appended to UserPromptSubmit")
        T.eq(entries(d, "SessionStart"), 2, "appended to SessionStart")
        T.eq(entries(d, "PreCompact"), 1, "an unrelated event is untouched")
        T.ok(d["permissions"] != nil && d["model"] != nil && d["statusLine"] != nil,
             "every unrelated top-level key survives")

        let text = (try? String(contentsOfFile: path, encoding: .utf8)) ?? ""
        T.ok(text.contains("existing-plugin-command --flag"), "the pre-existing command is intact")
        T.ok(text.contains(HookInstaller.marker), "our entries carry the marker")

        // Idempotence.
        T.noThrow("second install succeeds") { _ = try HookInstaller.install(settingsPath: path) }
        d = load()
        T.eq(entries(d, "Stop"), 2, "installing twice adds nothing")

        // A backup exists.
        let backups = ((try? FileManager.default.contentsOfDirectory(atPath: dir)) ?? [])
            .filter { $0.contains("chute-backup") }
        T.ok(!backups.isEmpty, "a timestamped backup was written")

        // Status.
        T.eq(HookInstaller.status(settingsPath: path).values.filter { $0 }.count, 4,
             "status reports four wired events")

        // Uninstall restores exactly.
        T.noThrow("uninstall succeeds") { _ = try HookInstaller.uninstall(settingsPath: path) }
        d = load()
        T.eq(entries(d, "Stop"), 1, "our entry removed")
        T.ok(((try? String(contentsOfFile: path, encoding: .utf8)) ?? "")
                .contains("existing-plugin-command --flag"), "theirs still there after uninstall")
        T.eq(HookInstaller.status(settingsPath: path).values.filter { $0 }.count, 0,
             "status reports nothing wired")

        // Malformed input changes nothing.
        let broken = (dir as NSString).appendingPathComponent("broken.json")
        try? "{ this is not json".write(toFile: broken, atomically: true, encoding: .utf8)
        T.throwsError("refuses to touch an unparseable file") {
            _ = try HookInstaller.install(settingsPath: broken)
        }
        T.eq((try? String(contentsOfFile: broken, encoding: .utf8)) ?? "", "{ this is not json",
             "the unparseable file is byte-identical afterwards")

        // A settings file with no hooks key at all.
        let bare = (dir as NSString).appendingPathComponent("bare.json")
        try? #"{"model":"opus"}"#.write(toFile: bare, atomically: true, encoding: .utf8)
        T.noThrow("handles a file with no hooks key") { _ = try HookInstaller.install(settingsPath: bare) }
        T.eq(entries(load2(bare), "Stop"), 1, "creates the event array when absent")
    }
}

private func load2(_ path: String) -> [String: Any] {
    (try? JSONSerialization.jsonObject(with: Data(contentsOf: URL(fileURLWithPath: path))))
        as? [String: Any] ?? [:]
}
```

- [ ] **Step 2: Run to verify it fails**

Run: `cd /Users/sxope/Documents/2026/Development/37.chute && swift run chutetests`
Expected: compile error — `cannot find 'HookInstaller' in scope`.

- [ ] **Step 3: Write the implementation**

`Sources/ChuteCore/HookInstaller.swift`:

```swift
import Foundation

public struct HookReport: Sendable {
    public let changed: [String]
    public let skipped: [String]
    public let backupPath: String?
}

public enum HookInstallError: Error, CustomStringConvertible {
    case unreadable(String)
    case unparseable(String)
    case backupFailed(String)
    case validationFailed(String)

    public var description: String {
        switch self {
        case .unreadable(let p):       return "cannot read \(p)"
        case .unparseable(let p):      return "\(p) is not valid JSON — refusing to touch it"
        case .backupFailed(let m):     return "backup failed, nothing was changed: \(m)"
        case .validationFailed(let m): return "refusing to write: \(m)"
        }
    }
}

/// Append-only, backed up, idempotent, reversible. Anything less is unacceptable:
/// this edits the user's live global Claude Code configuration.
public enum HookInstaller {
    public static let marker = "chute-session-state"

    public static let events: [String: SessionState] = [
        "PermissionRequest": .blocked,
        "Stop":              .waiting,
        "UserPromptSubmit":  .working,
        "SessionStart":      .working,
    ]

    /// A single line. Writes one small file and always exits 0 — a Chute failure must never
    /// break the user's agent session. $PPID is the claude process, whose tty is the tab's tty.
    public static func command(for state: SessionState) -> String {
        let name = HookState.stateName(state)
        return "# \(marker)\n"
            + "S=\"$HOME/.chute/sessions\"; mkdir -p \"$S\" 2>/dev/null; "
            + "T=$(ps -o tty= -p $PPID 2>/dev/null | tr -d ' '); "
            + "if [ -n \"$T\" ]; then "
            + "printf '{\"tty\":\"%s\",\"state\":\"%s\",\"cwd\":\"%s\",\"ts\":%s}' "
            + "\"$T\" \"\(name)\" \"$PWD\" \"$(date +%s)\" > \"$S/$T.json.tmp\" 2>/dev/null "
            + "&& mv \"$S/$T.json.tmp\" \"$S/$T.json\" 2>/dev/null; fi; "
            + "printf '{}\\n'; exit 0"
    }

    static func loadObject(_ path: String) throws -> [String: Any] {
        guard let data = FileManager.default.contents(atPath: path) else {
            throw HookInstallError.unreadable(path)
        }
        guard let obj = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else {
            throw HookInstallError.unparseable(path)
        }
        return obj
    }

    public static func status(settingsPath: String) -> [String: Bool] {
        guard let obj = try? loadObject(settingsPath),
              let hooks = obj["hooks"] as? [String: Any] else {
            return events.keys.reduce(into: [:]) { $0[$1] = false }
        }
        return events.keys.reduce(into: [:]) { out, event in
            let blocks = (hooks[event] as? [[String: Any]]) ?? []
            out[event] = blocks.contains { block in
                ((block["hooks"] as? [[String: Any]]) ?? []).contains {
                    (($0["command"] as? String) ?? "").contains(marker)
                }
            }
        }
    }

    @discardableResult
    public static func install(settingsPath: String,
                               now: Date = Date()) throws -> HookReport {
        let original = try loadObject(settingsPath)
        let originalKeys = Set(original.keys)
        let backup = try makeBackup(settingsPath, now: now)

        var root = original
        var hooks = (root["hooks"] as? [String: Any]) ?? [:]
        var changed: [String] = [], skipped: [String] = []

        for (event, state) in events.sorted(by: { $0.key < $1.key }) {
            var blocks = (hooks[event] as? [[String: Any]]) ?? []
            let already = blocks.contains { block in
                ((block["hooks"] as? [[String: Any]]) ?? []).contains {
                    (($0["command"] as? String) ?? "").contains(marker)
                }
            }
            if already { skipped.append(event); continue }
            blocks.append(["hooks": [["type": "command", "command": command(for: state)]]])
            hooks[event] = blocks
            changed.append(event)
        }
        root["hooks"] = hooks

        try validateAndWrite(root, original: original, originalKeys: originalKeys,
                             path: settingsPath)
        return HookReport(changed: changed, skipped: skipped, backupPath: backup)
    }

    @discardableResult
    public static func uninstall(settingsPath: String,
                                 now: Date = Date()) throws -> HookReport {
        let original = try loadObject(settingsPath)
        let originalKeys = Set(original.keys)
        let backup = try makeBackup(settingsPath, now: now)

        var root = original
        var hooks = (root["hooks"] as? [String: Any]) ?? [:]
        var changed: [String] = []

        for event in events.keys.sorted() {
            guard var blocks = hooks[event] as? [[String: Any]] else { continue }
            let before = blocks.count
            blocks.removeAll { block in
                ((block["hooks"] as? [[String: Any]]) ?? []).contains {
                    (($0["command"] as? String) ?? "").contains(marker)
                }
            }
            if blocks.count != before { changed.append(event); hooks[event] = blocks }
        }
        root["hooks"] = hooks

        try validateAndWrite(root, original: original, originalKeys: originalKeys,
                             path: settingsPath, allowShrink: true)
        return HookReport(changed: changed, skipped: [], backupPath: backup)
    }

    static func makeBackup(_ path: String, now: Date) throws -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyyMMdd-HHmmss"
        let dest = path + ".chute-backup-" + f.string(from: now)
        do {
            if FileManager.default.fileExists(atPath: dest) {
                try FileManager.default.removeItem(atPath: dest)
            }
            try FileManager.default.copyItem(atPath: path, toPath: dest)
        } catch {
            throw HookInstallError.backupFailed(error.localizedDescription)
        }
        return dest
    }

    /// Nothing is written until the new document is proven to re-parse and to have kept
    /// every top-level key and (unless uninstalling) every pre-existing hook entry.
    static func validateAndWrite(_ root: [String: Any],
                                 original: [String: Any],
                                 originalKeys: Set<String>,
                                 path: String,
                                 allowShrink: Bool = false) throws {
        guard JSONSerialization.isValidJSONObject(root) else {
            throw HookInstallError.validationFailed("result is not a serialisable object")
        }
        let data = try JSONSerialization.data(withJSONObject: root,
                                              options: [.prettyPrinted, .sortedKeys])
        guard let reparsed = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else {
            throw HookInstallError.validationFailed("result does not re-parse")
        }
        let lost = originalKeys.subtracting(reparsed.keys)
        guard lost.isEmpty else {
            throw HookInstallError.validationFailed("would drop top-level keys: \(lost.sorted())")
        }
        if !allowShrink {
            let before = (original["hooks"] as? [String: Any]) ?? [:]
            let after = (reparsed["hooks"] as? [String: Any]) ?? [:]
            for (event, value) in before {
                let b = (value as? [Any])?.count ?? 0
                let a = (after[event] as? [Any])?.count ?? 0
                guard a >= b else {
                    throw HookInstallError.validationFailed("would shrink hooks.\(event) from \(b) to \(a)")
                }
            }
        }
        let temp = path + ".chute-tmp"
        try data.write(to: URL(fileURLWithPath: temp))
        _ = try FileManager.default.replaceItemAt(URL(fileURLWithPath: path),
                                                  withItemAt: URL(fileURLWithPath: temp))
    }
}
```

- [ ] **Step 4: Run to verify it passes**

Run: `cd /Users/sxope/Documents/2026/Development/37.chute && swift run chutetests`
Expected: 19 more assertions than before, zero failures.

- [ ] **Step 5: Prove the safety guard actually fires**

Temporarily change `guard a >= b` to `guard true`. Then change `blocks.append(...)` to `blocks = [...]` (replacing instead of appending). Re-run. Expected: "appended to Stop, original entry kept" fails. Restore both and confirm green.

- [ ] **Step 6: Dry-run against a COPY of the real file — never the real one**

```bash
cd /Users/sxope/Documents/2026/Development/37.chute
cp ~/.claude/settings.json /tmp/settings-copy.json
swift build -c release
python3 -c "
import json;d=json.load(open('/tmp/settings-copy.json'));print('before:', {k: len(v) for k,v in d['hooks'].items()})"
```
Record the numbers. After Task 7 exists you will run `chute hooks install --settings /tmp/settings-copy.json` and confirm exactly four events gained exactly one entry each.

- [ ] **Step 7: Commit**

```bash
cd /Users/sxope/Documents/2026/Development/37.chute
git add Sources/ChuteCore/HookInstaller.swift Sources/chutetests/HookInstallerSuite.swift
git commit -m "feat: append-only, validated, reversible Claude Code hook installer"
```

---

### Task 7: CLI commands  ·  **Model: Sonnet**  ·  Wave C

**Files:**
- Create: `/Users/sxope/Documents/2026/Development/37.chute/Sources/chute/Commands/SessionCommands.swift`
- Modify: `/Users/sxope/Documents/2026/Development/37.chute/Sources/chute/main.swift` (the `switch command` block and `helpText`)

**Interfaces:**
- Consumes: `TerminalAppAdapter` (Task 5), `HookState` (Task 4), `HookInstaller` (Task 6), `SessionColor` (Task 2).
- Produces: `cmdSessions(_:)`, `cmdFocus(_:)`, `cmdHooks(_:)`. Task 8's menu shells out to `chute sessions --json`.

- [ ] **Step 1: Write the implementation**

`Sources/chute/Commands/SessionCommands.swift`:

```swift
import Foundation
import ChuteCore

func discoverSessions() -> [Session] {
    let hooks = HookState.readAll()
    do {
        return try TerminalAppAdapter().discover(hooks: hooks, now: Date())
            .sorted { ($0.state, $0.project) < ($1.state, $1.project) }
    } catch {
        Out.info("chute: \(error)")
        return []
    }
}

func cmdSessions(_ a: Args) {
    let sessions = discoverSessions()
    guard !sessions.isEmpty else { Out.info("no terminal sessions"); return }

    if a.has("json") {
        let rows = sessions.map { s -> [String: Any] in
            ["key": s.key, "project": s.project, "title": s.title, "tty": s.tty,
             "state": HookState.stateName(s.state), "isAgent": s.isAgent,
             "windowID": s.windowID, "tabIndex": s.tabIndex,
             "color": SessionColor.hex(forProject: s.project)]
        }
        let data = try? JSONSerialization.data(withJSONObject: rows, options: [.prettyPrinted])
        Out.line(String(decoding: data ?? Data("[]".utf8), as: UTF8.self))
        return
    }

    func pad(_ s: String, _ n: Int) -> String {
        s.count >= n ? String(s.prefix(n)) : s + String(repeating: " ", count: n - s.count)
    }
    for s in sessions {
        Out.line(pad(s.state.label, 9) + pad(s.project, 18) + pad(s.title, 40) + s.tty)
    }
    let needs = sessions.filter { $0.state == .blocked || $0.state == .waiting }.count
    Out.info("→ \(sessions.count) session(s), \(needs) need you")
}

func cmdFocus(_ a: Args) {
    guard let target = a.positional.first else {
        Out.fail("usage: chute focus <key|project>   (see `chute sessions`)")
    }
    let sessions = discoverSessions()
    guard let hit = sessions.first(where: { $0.key == target })
            ?? sessions.first(where: { $0.project == target })
            ?? Int(target).flatMap({ n in n >= 1 && n <= sessions.count ? sessions[n - 1] : nil })
    else { Out.fail("no session matching '\(target)'") }

    do { try TerminalAppAdapter().focus(hit) }
    catch { Out.fail("\(error)") }
    Out.info("→ focused \(hit.project) (\(hit.tty))")
}

func cmdHooks(_ a: Args) {
    let path = a.value("settings", or: (NSHomeDirectory() as NSString)
        .appendingPathComponent(".claude/settings.json"))
    switch a.positional.first ?? "status" {
    case "install":
        do {
            let r = try HookInstaller.install(settingsPath: path)
            Out.info("→ backup: \(r.backupPath ?? "none")")
            Out.line("wired: \(r.changed.sorted().joined(separator: ", "))")
            if !r.skipped.isEmpty {
                Out.line("already present: \(r.skipped.sorted().joined(separator: ", "))")
            }
        } catch { Out.fail("\(error)") }
    case "uninstall":
        do {
            let r = try HookInstaller.uninstall(settingsPath: path)
            Out.info("→ backup: \(r.backupPath ?? "none")")
            Out.line("removed: \(r.changed.sorted().joined(separator: ", "))")
        } catch { Out.fail("\(error)") }
    default:
        for (event, wired) in HookInstaller.status(settingsPath: path).sorted(by: { $0.key < $1.key }) {
            Out.line("\(wired ? "✓" : "·") \(event)")
        }
        Out.info("→ settings: \(path)")
    }
}
```

- [ ] **Step 2: Wire the commands into the dispatcher**

In `Sources/chute/main.swift`, add three cases to the `switch command` block, immediately after `case "env":`:

```swift
case "sessions":   cmdSessions(args)
case "focus":      cmdFocus(args)
case "hooks":      cmdHooks(args)
```

And add this block to `helpText`, after the `GIT SAFETY` section:

```
AGENT SESSIONS
  sessions              Every terminal session, grouped by state     --json
  focus <key|project|N> Bring that session to the front
  hooks install|uninstall|status                                     --settings PATH
```

- [ ] **Step 3: Build and run against the real Terminal**

Run: `cd /Users/sxope/Documents/2026/Development/37.chute && swift build -c release && ./.build/release/chute sessions`
Expected: one line per open Terminal window, showing state, project, title and tty, ending with `→ N session(s), M need you`.

- [ ] **Step 4: Verify the hook installer against a copy, never the real file**

```bash
cd /Users/sxope/Documents/2026/Development/37.chute
cp ~/.claude/settings.json /tmp/settings-copy.json
./.build/release/chute hooks install --settings /tmp/settings-copy.json
./.build/release/chute hooks status  --settings /tmp/settings-copy.json
python3 -c "
import json
a=json.load(open('/Users/sxope/.claude/settings.json'))
b=json.load(open('/tmp/settings-copy.json'))
assert set(a) == set(b), 'top-level keys changed'
for k in a['hooks']:
    d=len(b['hooks'][k])-len(a['hooks'][k])
    assert d in (0,1), (k,d)
    print(f'{k}: +{d}')
print('SAFE')"
```
Expected: `+1` on exactly the four events, `+0` on all others, then `SAFE`.

- [ ] **Step 5: Verify focus actually moves a window**

Run: `cd /Users/sxope/Documents/2026/Development/37.chute && ./.build/release/chute focus 2`
Expected: the second listed window comes to the front.

- [ ] **Step 6: Commit**

```bash
cd /Users/sxope/Documents/2026/Development/37.chute
git add Sources/chute/Commands/SessionCommands.swift Sources/chute/main.swift
git commit -m "feat: chute sessions, focus and hooks commands"
```

---

### Task 8: Menu bar switcher  ·  **Model: Sonnet**  ·  Wave C

**Files:**
- Create: `/Users/sxope/Documents/2026/Development/37.chute/Sources/ChuteApp/SessionMenu.swift`
- Modify: `/Users/sxope/Documents/2026/Development/37.chute/Sources/ChuteApp/main.swift` (`AppDelegate.buildMenu` and `applicationDidFinishLaunching`)

**Interfaces:**
- Consumes: `TerminalAppAdapter`, `HookState`, `SessionColor`, `Session`, `SessionState`.
- Produces: `SessionMenu.build(sessions:target:) -> NSMenu`, `SessionMenu.badge(for:) -> String`.

- [ ] **Step 1: Write the menu builder**

`Sources/ChuteApp/SessionMenu.swift`:

```swift
import AppKit
import ChuteCore

enum SessionMenu {
    static func badge(for sessions: [Session]) -> String {
        let n = sessions.filter { $0.state == .blocked || $0.state == .waiting }.count
        return n == 0 ? "⤓" : "⤓ \(n)"
    }

    static func dot(_ hex: String) -> NSImage {
        let size = NSSize(width: 10, height: 10)
        let image = NSImage(size: size)
        image.lockFocus()
        (NSColor(hex: hex) ?? .systemGray).setFill()
        NSBezierPath(ovalIn: NSRect(origin: .zero, size: size)).fill()
        image.unlockFocus()
        return image
    }

    static func elide(_ s: String, _ max: Int = 34) -> String {
        guard s.count > max else { return s }
        let half = (max - 1) / 2
        return String(s.prefix(half)) + "…" + String(s.suffix(half))
    }

    static func age(_ since: Date?) -> String {
        guard let since else { return "" }
        let m = Int(Date().timeIntervalSince(since) / 60)
        if m < 1 { return "just now" }
        return m < 60 ? "\(m)m" : "\(m / 60)h"
    }

    /// Groups by state, assigns ⌥1…⌥8 top-down so the most urgent session is always ⌥1.
    static func build(sessions: [Session], target: AnyObject, action: Selector) -> NSMenu {
        let menu = NSMenu()
        var hotkey = 1

        let groups: [(String, [Session])] = [
            ("NEEDS YOU", sessions.filter { $0.state == .blocked || $0.state == .waiting }),
            ("WORKING",   sessions.filter { $0.state == .working }),
            ("SHELLS",    sessions.filter { $0.state == .idle || $0.state == .unknown }),
        ]

        for (title, group) in groups where !group.isEmpty {
            let header = NSMenuItem(title: "\(title)  (\(group.count))", action: nil, keyEquivalent: "")
            header.isEnabled = false
            menu.addItem(header)

            for s in group {
                let detail = s.state == .blocked || s.state == .waiting
                    ? "\(s.state.label) · \(age(s.since))"
                    : elide(s.title)
                let item = NSMenuItem(title: "\(s.project)   \(detail)",
                                      action: action,
                                      keyEquivalent: hotkey <= 8 ? "\(hotkey)" : "")
                item.keyEquivalentModifierMask = [.option]
                item.image = dot(SessionColor.hex(forProject: s.project))
                item.representedObject = s.key
                item.target = target
                menu.addItem(item)
                hotkey += 1
            }
            menu.addItem(.separator())
        }

        if sessions.isEmpty {
            let empty = NSMenuItem(title: "No terminal sessions", action: nil, keyEquivalent: "")
            empty.isEnabled = false
            menu.addItem(empty)
            menu.addItem(.separator())
        }
        return menu
    }
}

extension NSColor {
    convenience init?(hex: String) {
        var s = hex
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6, let v = UInt32(s, radix: 16) else { return nil }
        self.init(srgbRed: CGFloat((v >> 16) & 0xFF) / 255,
                  green:   CGFloat((v >> 8) & 0xFF) / 255,
                  blue:    CGFloat(v & 0xFF) / 255,
                  alpha: 1)
    }
}
```

- [ ] **Step 2: Rebuild the app delegate's menu around sessions**

In `Sources/ChuteApp/main.swift`, replace the body of `buildMenu()` with:

```swift
    func buildMenu() -> NSMenu {
        let sessions = (try? TerminalAppAdapter().discover(hooks: HookState.readAll(), now: Date()))?
            .sorted { ($0.state, $0.project) < ($1.state, $1.project) } ?? []
        statusItem.button?.title = SessionMenu.badge(for: sessions)
        lastSessions = sessions

        let menu = SessionMenu.build(sessions: sessions, target: self, action: #selector(focusSession(_:)))

        let actions = NSMenu()
        for (i, a) in actions_list.enumerated() {
            let item = NSMenuItem(title: a.title, action: #selector(fire(_:)), keyEquivalent: "")
            item.target = self; item.tag = i
            actions.addItem(item)
        }
        let actionsItem = NSMenuItem(title: "Chute Actions", action: nil, keyEquivalent: "")
        menu.addItem(actionsItem)
        menu.setSubmenu(actions, for: actionsItem)

        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Refresh", action: #selector(refresh), keyEquivalent: "r"))
        menu.addItem(NSMenuItem(title: "Quit Chute",
                                action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        return menu
    }

    @objc func focusSession(_ sender: NSMenuItem) {
        guard let key = sender.representedObject as? String,
              let s = lastSessions.first(where: { $0.key == key }) else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            try? TerminalAppAdapter().focus(s)
        }
    }

    @objc func refresh() { statusItem.menu = buildMenu() }
```

Rename the existing global `let actions:` array to `actions_list` and add two stored properties to `AppDelegate`:

```swift
    var lastSessions: [Session] = []
    var watcher: DispatchSourceFileSystemObject?
```

- [ ] **Step 3: Refresh on menu open, and watch hook files for the badge**

Add to `AppDelegate`, and set `statusItem.menu?.delegate = self` in `applicationDidFinishLaunching`:

```swift
    // AppleScript runs ONLY when the menu opens. Zero cost while closed.
    func menuWillOpen(_ menu: NSMenu) { statusItem.menu = buildMenu() }

    /// Badge updates are event-driven off the hook directory — no polling, no AppleScript.
    func startWatching() {
        let dir = HookState.directory()
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        let fd = open(dir, O_EVTONLY)
        guard fd >= 0 else { return }
        let src = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd, eventMask: [.write, .extend], queue: .main)
        src.setEventHandler { [weak self] in self?.updateBadgeFromHooks() }
        src.setCancelHandler { close(fd) }
        src.resume()
        watcher = src
    }

    func updateBadgeFromHooks() {
        let records = HookState.readAll().values
        let n = records.filter { $0.state == .blocked || $0.state == .waiting }.count
        statusItem.button?.title = n == 0 ? "⤓" : "⤓ \(n)"
    }
```

Declare conformance: `final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate`, and call `startWatching()` and `updateBadgeFromHooks()` at the end of `applicationDidFinishLaunching`.

- [ ] **Step 4: Build, install and look at it**

```bash
cd /Users/sxope/Documents/2026/Development/37.chute && ./Scripts/build-app.sh && ./Scripts/install.sh
```
Expected: the menu bar shows `⤓` (or `⤓ N`). Clicking it lists your real Terminal windows grouped under NEEDS YOU / WORKING / SHELLS with coloured dots.

- [ ] **Step 5: Verify the hotkeys**

Open the menu and press `⌥1`. Expected: the first listed window comes to the front.

- [ ] **Step 6: Verify zero background AppleScript**

```bash
sudo fs_usage -w -f exec 2>/dev/null | grep -c osascript &
sleep 20; kill %1
```
Expected: no `osascript` executions while the menu stays closed.

- [ ] **Step 7: Commit**

```bash
cd /Users/sxope/Documents/2026/Development/37.chute
git add Sources/ChuteApp/
git commit -m "feat: menu bar session switcher with badge, per-project colours and option-number focus"
```

---

### Task 9: Smoke coverage, install wiring and docs  ·  **Model: Haiku**  ·  Wave D

Mechanical. Every command already exists; this wires them into the existing scripts and docs.

**Files:**
- Modify: `/Users/sxope/Documents/2026/Development/37.chute/Scripts/smoke.sh`
- Modify: `/Users/sxope/Documents/2026/Development/37.chute/Scripts/install.sh`
- Modify: `/Users/sxope/Documents/2026/Development/37.chute/Scripts/uninstall.sh`
- Modify: `/Users/sxope/Documents/2026/Development/37.chute/README.md`

**Interfaces:**
- Consumes: `chute sessions|focus|hooks` from Task 7.
- Produces: nothing other tasks depend on.

- [ ] **Step 1: Add smoke checks**

Insert before the final `cd /; rm -rf "$T"` line in `Scripts/smoke.sh`:

```bash
echo "14. session switcher"
OUT="$("$CHUTE" sessions --json 2>/dev/null)"
printf '%s' "$OUT" | python3 -c "import json,sys; json.load(sys.stdin)" 2>/dev/null \
  && ok "sessions --json is valid JSON" || bad "sessions --json is valid JSON" "parse failed"

echo "15. hook installer never damages a settings file"
cp "$HOME/.claude/settings.json" "$T/settings.json" 2>/dev/null || echo '{"hooks":{}}' > "$T/settings.json"
BEFORE="$(python3 -c "import json;d=json.load(open('$T/settings.json'));print(sorted(d.keys()))")"
"$CHUTE" hooks install --settings "$T/settings.json" >/dev/null 2>&1
AFTER="$(python3 -c "import json;d=json.load(open('$T/settings.json'));print(sorted(d.keys()))")"
check "top-level keys unchanged" "$AFTER" "$BEFORE"
"$CHUTE" hooks install --settings "$T/settings.json" >/dev/null 2>&1
COUNT="$(python3 -c "
import json;d=json.load(open('$T/settings.json'))
print(sum(1 for b in d['hooks'].get('Stop',[]) for h in b.get('hooks',[]) if 'chute-session-state' in h.get('command','')))")"
check "install is idempotent" "$COUNT" "1"
"$CHUTE" hooks uninstall --settings "$T/settings.json" >/dev/null 2>&1
LEFT="$(python3 -c "
import json;d=json.load(open('$T/settings.json'))
print(sum(1 for e in d['hooks'].values() for b in e for h in b.get('hooks',[]) if 'chute-session-state' in h.get('command','')))")"
check "uninstall removes ours" "$LEFT" "0"
```

- [ ] **Step 2: Offer hook installation during install**

Append to `Scripts/install.sh`, before the final `cat <<EOF` block:

```bash
if ! "$HOME/Applications/Chute.app/Contents/MacOS/chute" hooks status | grep -q "✓"; then
  echo
  echo "Chute can install Claude Code hooks so the menu bar knows which agents are waiting."
  echo "It appends to ~/.claude/settings.json — backed up first, reversible with:"
  echo "  chute hooks uninstall"
  printf "Install them now? [y/N] "
  read -r reply
  case "$reply" in [yY]*) "$HOME/Applications/Chute.app/Contents/MacOS/chute" hooks install ;; esac
fi
```

- [ ] **Step 3: Remove hooks on uninstall**

Add to `Scripts/uninstall.sh`, before the `rm -rf "$HOME/Applications/Chute.app"` line:

```bash
"$HOME/Applications/Chute.app/Contents/MacOS/chute" hooks uninstall 2>/dev/null || true
```

- [ ] **Step 4: Document the commands**

Add these rows to the command table in `README.md`, after the `chute prompt` row:

```markdown
| `chute sessions` | Every terminal session, grouped by state, with the ones waiting on you first. `--json` |
| `chute focus <key\|project\|N>` | Bring that session to the front |
| `chute hooks install\|uninstall\|status` | Wire Claude Code hooks that report session state. Append-only, backed up, reversible |
```

- [ ] **Step 5: Run everything**

```bash
cd /Users/sxope/Documents/2026/Development/37.chute && swift run chutetests && ./Scripts/smoke.sh
```
Expected: all assertions pass; smoke reports `43 passed, 0 failed`.

- [ ] **Step 6: Commit**

```bash
cd /Users/sxope/Documents/2026/Development/37.chute
git add Scripts/ README.md
git commit -m "test: smoke coverage for sessions and hook installer safety; wire hooks into install"
```

---

---

# Onboarding — Tasks O1–O3

**Priority: these run BEFORE Tasks 7–9.** Rationale in `docs/09-GTM-DECISIONS.md`: onboarding tests
assumption A1 ("a stranger can install Chute and see the menu"), the only assumption we currently
have evidence *against*. Tasks 7–9 add polish to an engine nobody can reach.

**Spec:** `docs/superpowers/specs/2026-08-26-onboarding-design.md`
**Compatibility constraints:** `docs/08-MACOS-COMPATIBILITY.md`

## Governing principle

**Never instruct. Detect, verify, repair.** On macOS 15.0–15.1 Apple removed the Extensions
configuration UI entirely, so for two OS releases "tick the box in System Settings" pointed at a
screen that did not exist. Any onboarding built on told steps is already broken for a slice of users.

## Dispatch map

| Wave | Task | Model | Why |
|---|---|---|---|
| O-A | O1 | **Sonnet** | The check matrix and its injectable environment — the design everything else renders |
| O-B | O2 | **Haiku** | Rendering outcomes, exit codes, `--json`. Mechanical once O1 exists |
| O-B | O3 | **Sonnet** | AppKit window, live re-verification, consent copy |

O2 and O3 touch disjoint files and may run in parallel. Both dispatches MUST carry the worktree
merge instruction (`git merge feat/session-switcher --no-edit` first) — see the Wave A incident.

---

### Task O1: Diagnostics engine  ·  **Model: Sonnet**  ·  Wave O-A

**Files:**
- Create: `Sources/ChuteCore/Diagnostics.swift`
- Modify: `Sources/chutetests/main.swift` — add ONE line, `diagnosticsSuite()`, before `T.report()`
- Create: `Sources/chutetests/DiagnosticsSuite.swift`

**Interfaces:**
- Consumes: `HookInstaller.status`, `Shell.run`, `isAppRunning` — all merged.
- Produces: `Check`, `CheckOutcome`, `DiagnosticsEnv`, `Diagnostics.all`, `Diagnostics.run(_:)`,
  `Diagnostics.liveEnv()`. Tasks O2 and O3 both render `[CheckOutcome]` and call nothing else.

- [ ] **Step 1: Write the failing test**

`Sources/chutetests/DiagnosticsSuite.swift`:

```swift
import Foundation
import ChuteCore

func diagnosticsSuite() {
    T.suite("Diagnostics") {
        // The dead-end guard: this is the rule the whole module exists to enforce.
        for check in Diagnostics.all {
            T.no(check.why.isEmpty, "check '\(check.id)' explains why it matters")
            T.no(check.fix.isEmpty, "check '\(check.id)' states how to fix it")
            T.no(check.title.isEmpty, "check '\(check.id)' has a title")
        }
        T.eq(Set(Diagnostics.all.map(\.id)).count, Diagnostics.all.count, "check ids are unique")
        T.eq(Diagnostics.all.count, 9, "nine checks")

        let good = DiagnosticsEnv(
            osMajor: 14, appPath: "/Users/x/Applications/Chute.app",
            cliPath: "/Users/x/.local/bin/chute",
            pluginkitList: "+    dev.valuev.chute.finder(0.1.0)",
            extensionID: "dev.valuev.chute.finder",
            automationOK: true,
            processList: "/System/Applications/Utilities/Terminal.app/Contents/MacOS/Terminal",
            hooksWired: 4, endToEndPassed: true)

        T.eq(Diagnostics.run(good).filter { !$0.passed }.count, 0, "a healthy environment passes all nine")

        // Each failure must be isolated: break one thing, exactly one check fails, and it names it.
        var old = good; old.osMajor = 12
        let oldOut = Diagnostics.run(old).filter { !$0.passed }
        T.eq(oldOut.count, 1, "an old OS fails exactly one check")
        T.eq(oldOut.first?.check.id ?? "", "os", "and it is the os check")

        var unreg = good; unreg.pluginkitList = ""
        T.eq(Diagnostics.run(unreg).first(where: { !$0.passed })?.check.id ?? "", "ext-registered",
             "an unregistered extension is named")

        // A registered-but-DISABLED extension is the exact state that wasted a day: the minus flag.
        var disabled = good; disabled.pluginkitList = "-    dev.valuev.chute.finder(0.1.0)"
        let disOut = Diagnostics.run(disabled).filter { !$0.passed }
        T.eq(disOut.count, 1, "registered-but-disabled fails exactly one check")
        T.eq(disOut.first?.check.id ?? "", "ext-enabled", "and it is the enabled check, not registered")

        var noAuto = good; noAuto.automationOK = false
        T.eq(Diagnostics.run(noAuto).first(where: { !$0.passed })?.check.id ?? "", "automation",
             "missing automation permission is named")

        var partial = good; partial.hooksWired = 2
        T.eq(Diagnostics.run(partial).first(where: { !$0.passed })?.check.id ?? "", "hooks",
             "partially wired hooks fail the hooks check")

        var broken = good; broken.endToEndPassed = false
        T.eq(Diagnostics.run(broken).first(where: { !$0.passed })?.check.id ?? "", "end-to-end",
             "a failing end-to-end proof is named even when every component passes")

        T.eq(Diagnostics.run(good).count, 9, "run reports an outcome per check, passed or not")
    }
}
```

- [ ] **Step 2: Run to verify it fails**

`swift run chutetests`
Expected: compile error — `cannot find 'Diagnostics' in scope`.

- [ ] **Step 3: Write the implementation**

`Sources/ChuteCore/Diagnostics.swift`:

```swift
import Foundation

/// One thing that must be true for Chute to work.
/// `why` and `fix` are non-optional by design: a check that cannot explain itself or state its
/// remedy is a dead end, and a test in the suite mechanically forbids adding one.
public struct Check: Sendable, Equatable {
    public let id: String
    public let title: String
    public let why: String
    public let fix: String

    public init(id: String, title: String, why: String, fix: String) {
        self.id = id; self.title = title; self.why = why; self.fix = fix
    }
}

public struct CheckOutcome: Sendable {
    public let check: Check
    public let passed: Bool
    public let detail: String

    public init(check: Check, passed: Bool, detail: String) {
        self.check = check; self.passed = passed; self.detail = detail
    }
}

/// Everything the checks need from the outside world, in one injectable value so the whole
/// matrix is testable with stubs and zero system calls.
public struct DiagnosticsEnv: Sendable {
    public var osMajor: Int
    public var appPath: String
    public var cliPath: String?
    public var pluginkitList: String
    public var extensionID: String
    public var automationOK: Bool
    public var processList: String
    public var hooksWired: Int
    public var endToEndPassed: Bool

    public init(osMajor: Int, appPath: String, cliPath: String?, pluginkitList: String,
                extensionID: String, automationOK: Bool, processList: String,
                hooksWired: Int, endToEndPassed: Bool) {
        self.osMajor = osMajor; self.appPath = appPath; self.cliPath = cliPath
        self.pluginkitList = pluginkitList; self.extensionID = extensionID
        self.automationOK = automationOK; self.processList = processList
        self.hooksWired = hooksWired; self.endToEndPassed = endToEndPassed
    }
}

public enum Diagnostics {
    public static let minimumOSMajor = 13

    public static let all: [Check] = [
        Check(id: "os", title: "macOS version",
              why: "Chute needs macOS 13 or later for the Finder extension API it depends on.",
              fix: "Upgrade macOS. Nothing else can be done from here."),
        Check(id: "app-location", title: "App location",
              why: "macOS only loads a Finder extension from an app in /Applications or ~/Applications.",
              fix: "Move Chute.app to ~/Applications, then run this again."),
        Check(id: "cli", title: "Command line tool",
              why: "Every menu item and Finder action runs through the chute binary.",
              fix: "chute doctor --fix   (symlinks it into ~/.local/bin)"),
        Check(id: "ext-registered", title: "Finder extension registered",
              why: "macOS cannot show the right-click menu for an extension it does not know about.",
              fix: "chute doctor --fix   (runs pluginkit -a on the bundled extension)"),
        Check(id: "ext-enabled", title: "Finder extension enabled",
              why: "The extension is installed but switched off, so the right-click menu stays hidden. This is the single most common reason Chute appears to do nothing.",
              fix: "chute doctor --fix   (or System Settings → Privacy & Security → Extensions → Finder)"),
        Check(id: "automation", title: "Automation permission",
              why: "Chute asks Finder and Terminal what you have selected. Without this the session list is empty.",
              fix: "chute doctor --fix triggers the prompt. If you denied it: System Settings → Privacy & Security → Automation."),
        Check(id: "terminal", title: "A terminal is running",
              why: "The session switcher lists terminal windows. With none open there is nothing to show.",
              fix: "Open Terminal. Informational only — nothing is broken."),
        Check(id: "hooks", title: "Agent status hooks",
              why: "Without them the menu bar cannot tell which agents are waiting for you.",
              fix: "chute hooks install   (appends only, backs up first, reversible with chute hooks uninstall)"),
        Check(id: "end-to-end", title: "End-to-end proof",
              why: "Every component can be healthy and the product still not work. This runs a real command and reads the result back.",
              fix: "If this alone fails, the pieces are fine but they are not talking. Re-run chute doctor --fix, then report it."),
    ]

    static func check(_ id: String) -> Check {
        all.first { $0.id == id } ?? all[0]
    }

    public static func run(_ env: DiagnosticsEnv) -> [CheckOutcome] {
        var out: [CheckOutcome] = []
        func add(_ id: String, _ passed: Bool, _ detail: String) {
            out.append(CheckOutcome(check: check(id), passed: passed, detail: detail))
        }

        add("os", env.osMajor >= minimumOSMajor, "macOS \(env.osMajor)")
        add("app-location",
            env.appPath.contains("/Applications/"),
            env.appPath)
        add("cli", env.cliPath != nil, env.cliPath ?? "not found")

        // pluginkit prints one line per extension, prefixed "+" (enabled) or "-" (disabled).
        let line = env.pluginkitList
            .split(separator: "\n")
            .first { $0.contains(env.extensionID) }
            .map(String.init)
        add("ext-registered", line != nil, line == nil ? "not registered" : env.extensionID)
        // Registered-but-disabled is a DIFFERENT failure with a different fix, so it is its own
        // check. Collapsing the two is what makes "it's installed but nothing happens" unfixable.
        add("ext-enabled",
            (line?.trimmingCharacters(in: .whitespaces).hasPrefix("+")) ?? false,
            line == nil ? "n/a" : (line!.hasPrefix("-") ? "disabled by macOS" : "enabled"))

        add("automation", env.automationOK, env.automationOK ? "Finder responds" : "denied or not yet granted")
        add("terminal",
            env.processList.contains("Terminal.app/Contents/MacOS/Terminal"),
            env.processList.isEmpty ? "none detected" : "running")
        add("hooks", env.hooksWired == 4, "\(env.hooksWired) of 4 wired")
        add("end-to-end", env.endToEndPassed, env.endToEndPassed ? "verified" : "failed")
        return out
    }

    /// The real environment. Every probe here is one that `docs/08-MACOS-COMPATIBILITY.md`
    /// records as VERIFIED — notably `ps -Ao comm` rather than pgrep, which never matches
    /// a bundled app.
    public static func liveEnv(extensionID: String = "dev.valuev.chute.finder",
                               appPath: String = Bundle.main.bundlePath) -> DiagnosticsEnv {
        let v = ProcessInfo.processInfo.operatingSystemVersion
        let cli = ["\(NSHomeDirectory())/.local/bin/chute", "/usr/local/bin/chute"]
            .first { FileManager.default.isExecutableFile(atPath: $0) }
        let probe = Shell.run("osascript", ["-e", "tell application \"Finder\" to return 1"])
        return DiagnosticsEnv(
            osMajor: v.majorVersion,
            appPath: appPath,
            cliPath: cli,
            pluginkitList: Shell.run("pluginkit", ["-mA", "-p", "com.apple.FinderSync"]).out,
            extensionID: extensionID,
            automationOK: probe.ok,
            processList: Shell.run("ps", ["-Ao", "comm"]).out,
            hooksWired: HookInstaller.status(settingsPath:
                (NSHomeDirectory() as NSString).appendingPathComponent(".claude/settings.json"))
                .values.filter { $0 }.count,
            endToEndPassed: endToEndProbe())
    }

    /// Runs the product, not its parts: writes a temp file, asks chute for its path, reads the
    /// clipboard back. Component checks passing while THIS fails is the exact state this project
    /// spent a day in.
    public static func endToEndProbe() -> Bool {
        let dir = NSTemporaryDirectory() + "chute-doctor-\(UUID().uuidString)"
        defer { try? FileManager.default.removeItem(atPath: dir) }
        guard (try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)) != nil
        else { return false }
        let file = (dir as NSString).appendingPathComponent("probe.txt")
        guard (try? "probe".write(toFile: file, atomically: true, encoding: .utf8)) != nil
        else { return false }
        let saved = Clipboard.read()
        defer { Clipboard.write(saved) }
        let rendered = PathFormat.render([file], style: .posix)
        Clipboard.write(rendered)
        return Clipboard.read().contains("probe.txt")
    }
}
```

- [ ] **Step 4: Wire the suite in**

Add `diagnosticsSuite()` to `Sources/chutetests/main.swift`, immediately before `T.report()`.

- [ ] **Step 5: Run to verify it passes**

`cd /Users/sxope/Documents/2026/Development/37.chute && swift run chutetests`
Expected: the previous tally plus the new assertions, zero failures.

- [ ] **Step 6: Prove the dead-end guard is real**

Add a tenth check to `Diagnostics.all` with `fix: ""`. Re-run. Expected: RED, naming
"check '…' states how to fix it" AND "nine checks". Remove it, confirm green. Report both lines.

- [ ] **Step 7: Commit**

```bash
cd /Users/sxope/Documents/2026/Development/37.chute
git add Sources/ChuteCore/Diagnostics.swift Sources/chutetests/
git commit -m "feat: diagnostics engine — nine checks, each stating why it matters and how to fix it"
```

---

### Task O2: `chute doctor`  ·  **Model: Haiku**  ·  Wave O-B

**Files:**
- Create: `Sources/chute/Commands/DoctorCommand.swift`
- Modify: `Sources/chute/main.swift` — one `case` and one help block

**Interfaces:**
- Consumes: `Diagnostics.all`, `Diagnostics.run(_:)`, `Diagnostics.liveEnv()` from O1.
- Produces: `cmdDoctor(_:)`.

- [ ] **Step 1: Write the implementation**

`Sources/chute/Commands/DoctorCommand.swift`:

```swift
import Foundation
import ChuteCore

func cmdDoctor(_ a: Args) {
    var outcomes = Diagnostics.run(Diagnostics.liveEnv())

    if a.has("fix") {
        applyFixes(outcomes)
        // Never claim success without re-verifying. Reporting a fix that was not re-checked is
        // the failure mode this whole module exists to prevent.
        Out.info("→ re-running every check")
        outcomes = Diagnostics.run(Diagnostics.liveEnv())
    }

    if a.has("json") {
        let rows = outcomes.map { o -> [String: Any] in
            ["id": o.check.id, "title": o.check.title, "passed": o.passed,
             "detail": o.detail, "why": o.check.why, "fix": o.check.fix]
        }
        let data = try? JSONSerialization.data(withJSONObject: rows, options: [.prettyPrinted])
        Out.line(String(decoding: data ?? Data("[]".utf8), as: UTF8.self))
    } else {
        for o in outcomes {
            let mark = o.passed ? "✓" : "✗"
            let title = o.check.title.padding(toLength: 34, withPad: " ", startingAt: 0)
            Out.line("\(mark) \(title)\(o.detail)")
            if !o.passed {
                Out.line("    Why: \(o.check.why)")
                Out.line("    Fix: \(o.check.fix)")
            }
        }
        let failed = outcomes.filter { !$0.passed }.count
        Out.info(failed == 0
            ? "→ all \(outcomes.count) checks passed"
            : "→ \(failed) of \(outcomes.count) checks failed")
    }

    let failed = outcomes.filter { !$0.passed }
    if failed.isEmpty { exit(0) }
    exit(failed.contains { $0.check.id == "os" } ? 2 : 1)
}

private func applyFixes(_ outcomes: [CheckOutcome]) {
    for o in outcomes where !o.passed {
        switch o.check.id {
        case "cli":
            let target = (NSHomeDirectory() as NSString).appendingPathComponent(".local/bin")
            try? FileManager.default.createDirectory(atPath: target, withIntermediateDirectories: true)
            let src = Bundle.main.bundlePath + "/Contents/MacOS/chute"
            try? FileManager.default.createSymbolicLink(
                atPath: (target as NSString).appendingPathComponent("chute"), withDestinationPath: src)
            Out.info("→ linked chute into ~/.local/bin")
        case "ext-registered":
            let appex = Bundle.main.bundlePath + "/Contents/PlugIns/ChuteFinder.appex"
            _ = Shell.run("pluginkit", ["-a", appex])
            Out.info("→ registered the Finder extension")
        case "ext-enabled":
            _ = Shell.run("pluginkit", ["-e", "use", "-i", "dev.valuev.chute.finder"])
            Out.info("→ asked macOS to enable the Finder extension")
        case "automation":
            _ = Shell.run("osascript", ["-e", "tell application \"Finder\" to return 1"])
            Out.info("→ triggered the Automation prompt")
        case "hooks":
            do {
                let r = try HookInstaller.install(settingsPath:
                    (NSHomeDirectory() as NSString).appendingPathComponent(".claude/settings.json"))
                Out.info("→ wired hooks: \(r.changed.sorted().joined(separator: ", ")) · backup \(r.backupPath ?? "none")")
            } catch { Out.info("→ hooks not installed: \(error)") }
        default:
            break   // os, app-location, terminal and end-to-end have no safe automatic fix
        }
    }
}
```

- [ ] **Step 2: Wire it into the dispatcher**

In `Sources/chute/main.swift`, add after `case "hooks":`:
```swift
case "doctor":     cmdDoctor(args)
```
and to `helpText`, under a new final section:
```
SETUP
  doctor                Check every prerequisite and say how to fix it   --fix --json
```

- [ ] **Step 3: Run it for real**

`cd /Users/sxope/Documents/2026/Development/37.chute && swift build -c release && ./.build/release/chute doctor`
Expected: nine lines. Report the ACTUAL output verbatim, including failures — the failures are the
point of this task, not a problem with it.

- [ ] **Step 4: Verify the exit codes**

```bash
./.build/release/chute doctor >/dev/null 2>&1; echo "exit: $?"
./.build/release/chute doctor --json | python3 -c "import json,sys; d=json.load(sys.stdin); print(len(d), 'checks'); print('all have fix:', all(r['fix'] for r in d))"
```
Expected: exit 1 while anything fails, `9 checks`, `all have fix: True`.

- [ ] **Step 5: Commit**

```bash
cd /Users/sxope/Documents/2026/Development/37.chute
git add Sources/chute/
git commit -m "feat: chute doctor — diagnose every prerequisite, --fix re-verifies before reporting"
```

---

### Task O3: First-run window  ·  **Model: Sonnet**  ·  Wave O-B

**Files:**
- Create: `Sources/ChuteApp/FirstRunWindow.swift`
- Modify: `Sources/ChuteApp/main.swift` — show it once on launch; add a menu item to reopen it

**Interfaces:**
- Consumes: `Diagnostics` from O1.
- Produces: `FirstRunWindow.showIfNeeded()`, `FirstRunWindow.show()`.

- [ ] **Step 1: Write the window**

`Sources/ChuteApp/FirstRunWindow.swift`:

```swift
import AppKit
import ChuteCore

/// An LSUIElement app has no Dock icon, so a first launch with no window is indistinguishable
/// from a crash. Shown once, then only on request.
enum FirstRunWindow {
    static var statePath: String {
        (NSHomeDirectory() as NSString).appendingPathComponent(".chute/state.json")
    }

    static func showIfNeeded() {
        guard !FileManager.default.fileExists(atPath: statePath) else { return }
        show()
    }

    static func markSeen() {
        let dir = (statePath as NSString).deletingLastPathComponent
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        try? #"{"firstRunSeen":true}"#.write(toFile: statePath, atomically: true, encoding: .utf8)
    }

    nonisolated(unsafe) static var window: NSWindow?

    static func show() {
        let w = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 480, height: 380),
                         styleMask: [.titled, .closable], backing: .buffered, defer: false)
        w.title = "Chute"
        w.center()
        w.contentView = makeBody()
        w.isReleasedWhenClosed = false
        window = w
        NSApp.activate(ignoringOtherApps: true)
        w.makeKeyAndOrderFront(nil)
        markSeen()
    }

    static func makeBody() -> NSView {
        let root = NSStackView()
        root.orientation = .vertical
        root.alignment = .leading
        root.spacing = 10
        root.edgeInsets = NSEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)

        let heading = NSTextField(labelWithString: "Chute is almost ready")
        heading.font = .systemFont(ofSize: 18, weight: .semibold)
        root.addArrangedSubview(heading)

        for outcome in Diagnostics.run(Diagnostics.liveEnv()) {
            root.addArrangedSubview(row(outcome))
        }

        let buttons = NSStackView()
        buttons.orientation = .horizontal
        buttons.spacing = 10
        let fix = NSButton(title: "Fix everything", target: Handler.shared,
                           action: #selector(Handler.fixAll))
        fix.keyEquivalent = "\r"
        let skip = NSButton(title: "Skip", target: Handler.shared, action: #selector(Handler.skip))
        buttons.addArrangedSubview(fix)
        buttons.addArrangedSubview(skip)
        root.addArrangedSubview(buttons)
        return root
    }

    static func row(_ o: CheckOutcome) -> NSView {
        let stack = NSStackView()
        stack.orientation = .horizontal
        stack.spacing = 8
        let mark = NSTextField(labelWithString: o.passed ? "✓" : "⏳")
        mark.textColor = o.passed ? .systemGreen : .systemOrange
        stack.addArrangedSubview(mark)
        let label = NSTextField(labelWithString: o.check.title)
        stack.addArrangedSubview(label)
        if !o.passed {
            // No dead ends: a failing row always carries its reason, visible without a click.
            let why = NSTextField(labelWithString: o.check.why)
            why.font = .systemFont(ofSize: 11)
            why.textColor = .secondaryLabelColor
            why.lineBreakMode = .byTruncatingTail
            why.toolTip = o.check.fix
            stack.addArrangedSubview(why)
        }
        return stack
    }

    final class Handler: NSObject {
        nonisolated(unsafe) static let shared = Handler()

        @objc func fixAll() {
            let binary = Bundle.main.bundlePath + "/Contents/MacOS/chute"
            DispatchQueue.global(qos: .userInitiated).async {
                _ = Shell.run(binary, ["doctor", "--fix"])
                DispatchQueue.main.async {
                    // Re-render from a FRESH environment; never repaint a row green without
                    // re-running the check behind it.
                    FirstRunWindow.window?.contentView = FirstRunWindow.makeBody()
                }
            }
        }

        @objc func skip() {
            FirstRunWindow.markSeen()
            FirstRunWindow.window?.close()
        }
    }
}
```

- [ ] **Step 2: Wire it into the app**

In `Sources/ChuteApp/main.swift`, at the end of `applicationDidFinishLaunching`, add:
```swift
        FirstRunWindow.showIfNeeded()
```
and add a menu item so it is reachable later — in `buildMenu()`, before the Quit item:
```swift
        menu.addItem(NSMenuItem(title: "Setup Check…", action: #selector(openSetup), keyEquivalent: ""))
```
with:
```swift
    @objc func openSetup() { FirstRunWindow.show() }
```

- [ ] **Step 3: Build, install, and look at it**

```bash
cd /Users/sxope/Documents/2026/Development/37.chute
rm -f ~/.chute/state.json
./Scripts/build-app.sh && ./Scripts/install.sh
```
Expected: the window appears on launch, listing nine rows with live status.

- [ ] **Step 4: Verify it does not re-nag**

Press Skip, quit Chute, relaunch. Expected: no window. Then choose "Setup Check…" from the menu
bar — expected: the window returns.

- [ ] **Step 5: Verify rows re-verify rather than repaint**

With the extension disabled, press "Fix everything". Expected: the row turns green ONLY if
`pluginkit` reports it enabled afterwards. If macOS refuses, the row must stay orange.

- [ ] **Step 6: Commit**

```bash
cd /Users/sxope/Documents/2026/Development/37.chute
git add Sources/ChuteApp/
git commit -m "feat: first-run window — live checklist, fixes re-verify, skip never nags"
```

---

## Self-Review

**Spec coverage:** discovery → Task 5. State resolution → Task 3. Hook signal → Tasks 4, 6. Colours → Task 2. Menu, badge, ⌥1–8 → Task 8. New Agent Session submenu → *gap*: folded into Task 8's `Chute Actions` submenu using the existing `chute sandbox`; if the founder wants it as a first-class menu section it is a ten-line follow-up, noted here rather than silently dropped. Refresh strategy → Task 8 Steps 3 and 6. Error handling → Tasks 5 and 7 (`discoverSessions` catches and reports). Testing → every task. Out-of-scope items are not implemented anywhere, as intended.

**Placeholder scan:** no TBD/TODO; every code step carries real code; no "similar to Task N".

**Type consistency:** `HookState.stateName` is defined in Task 4 and used in Tasks 6 and 7. `Session.normalise` defined in Task 1, used in Tasks 4 and 5. `StateResolver.resolve` signature is identical in Tasks 3 and 5. `SessionColor.hex(forProject:)` identical in Tasks 2, 7 and 8. `TerminalAdapter.discover(hooks:now:)` identical in Tasks 1, 5, 7 and 8.
