import Foundation

/// Terminal.app via AppleScript. No Accessibility permission, no process-table polling.
/// Fields are separated by ASCII US (0x1F) and records by RS (0x1E) because window titles
/// legitimately contain commas, dashes, quotes and emoji.
public enum TerminalError: Error, CustomStringConvertible {
    case notRunning(String)
    case scriptFailed(String)

    public var description: String {
        switch self {
        case .notRunning(let app): return "\(app) is not running"
        case .scriptFailed(let m):  return "AppleScript failed: \(m)"
        }
    }
}

/// ponytail: no `TerminalAdapter` protocol. One conformer, three call sites, all of which
/// construct this type by name; add the protocol back when a second terminal exists.
public struct TerminalAppAdapter {
    public let kind: TerminalKind = .terminalApp
    public init() {}

    static let US = "\u{1F}"
    static let RS = "\u{1E}"

    /// Windows and tabs come and go WHILE this runs — you close a terminal, an agent finishes, a
    /// tab opens. Without the `try` blocks the whole listing dies on
    /// "Can't get item 13 of every window. Invalid index. (-1719)" and the menu shows nothing at
    /// all because one window shut half a second ago. Each window and each tab is therefore
    /// collected independently: a session that vanishes mid-scan is simply absent from the list,
    /// which is exactly what it is.
    ///
    /// PUBLIC so `Scripts/bench.swift` can time the exact script `discover()` runs, in isolation
    /// from the `SystemVitals.sample()` + `SessionCwd.map` work `discover()` also pays for — see
    /// docs/specs/PERFORMANCE.md. No behaviour change: still only read from `discover()` itself.
    public static let discoveryScript = """
    tell application "Terminal"
        set out to ""
        repeat with w in windows
            try
                set wid to id of w
                set wname to name of w
                set idx to 0
                repeat with t in tabs of w
                    set idx to idx + 1
                    try
                        set out to out & wid & "\(US)" & wname & "\(US)" & idx & "\(US)" & ¬
                            (tty of t) & "\(US)" & (busy of t) & "\(US)" & (selected of t) & "\(US)" & ¬
                            (processes of t as string) & "\(US)" & (custom title of t) & "\(RS)"
                    end try
                end repeat
            end try
        end repeat
        return out
    end tell
    """

    public func discover(hooks: [String: HookRecord], now: Date,
                         samples: [ProcessSample]? = nil) throws -> [Session] {
        guard isAppRunning(bundleExecutable: "Terminal.app/Contents/MacOS/Terminal") else {
            throw TerminalError.notRunning("Terminal")
        }
        let result = Shell.run("osascript", ["-e", Self.discoveryScript])
        guard result.ok else { throw TerminalError.scriptFailed(result.err) }
        // ONE MAP FOR THE WHOLE MENU, not a lookup per row. The caller already sampled the
        // process table for the CPU and memory columns, so passing it in costs nothing; measured
        // 2026-09-08, resolving all 60 tty processes took under a millisecond.
        let byTTY = SessionCwd.map(samples ?? SystemVitals.sample(),
                                   cwdOf: ProcessIdentity.workingDirectory)
        return Self.parse(result.out, hooks: hooks, now: now, cwdFor: { byTTY[$0] })
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
    /// `cwdFor` answers "where is this tty", from the kernel. It is injected rather than called
    /// because it is a syscall and `parse` is the pure function the suite drives.
    ///
    /// IT IS NOT A FALLBACK FOR THE HOOK — it is a SECOND SOURCE, and the hook still outranks it.
    /// A hook records where the agent was when it last reported; the kernel says where the
    /// process is right now. They agree almost always, and when they do not, the hook is the one
    /// tied to the state being displayed beside it.
    public static func parse(_ raw: String, hooks: [String: HookRecord], now: Date,
                             cwdFor: (String) -> String? = { _ in nil }) -> [Session] {
        raw.components(separatedBy: RS).compactMap { record -> Session? in
            let f = record.components(separatedBy: US)
            guard f.count >= 8, let windowID = Int(f[0].trimmingCharacters(in: .whitespacesAndNewlines))
            else { return nil }

            let tty = Session.normalise(tty: f[3])
            let processes = f[6]
            let title = f[7]
            let agent = agentName(in: processes)
            let busy = f[4].trimmingCharacters(in: .whitespaces) == "true"
            let hook = hooks[tty]

            return Session(
                key: Session.makeKey(kind: .terminalApp, windowID: windowID, tty: tty),
                kind: .terminalApp,
                windowID: windowID,
                tabIndex: Int(f[2]) ?? 1,
                tty: tty,
                // ONE DERIVATION, both surfaces — see ProjectName.swift's header comment for the
                // incident (badge and menu naming the same session two different things) this
                // closes. `hook?.cwd` is the authoritative source when it exists; the window
                // title (`f[1]`) is only ever the last resort inside `ProjectName.of` itself.
                project: ProjectName.of(cwd: hook?.cwd ?? cwdFor(tty), windowTitle: f[1]),
                title: title,
                agent: agent,
                busy: busy,
                state: StateResolver.resolve(hook: hook, isAgent: agent != nil, now: now),
                since: hook?.timestamp,
                sessionID: hook?.sessionID,
                // THE PATH THE NAME WAS DERIVED FROM, shown on the row's second line. Falling
                // back to the kernel here is what ended eight rows of `no project derived` on a
                // machine whose Terminal tabs were displaying the full path an inch away —
                // Antigravity ships no hooks, so `hook?.cwd` is nil for every one of them.
                cwd: hook?.cwd ?? cwdFor(tty)
            )
        }
    }

    /// WHICH agent is running in this tab, by name, from Terminal's own process list.
    ///
    /// `cursor` was missing, so a Cursor terminal read as a plain shell and never appeared under
    /// "Agents Working". The longest match wins rather than the first, so a table reordering
    /// cannot change the answer and "claude" cannot mask a longer name containing it.
    ///
    /// This is a substring test over a comma-joined list, which is deliberately generous: the
    /// executable is sometimes "claude", sometimes "cursor-agent", sometimes wrapped in
    /// `caffeinate ◂ claude`. A false positive costs a row in the wrong group; a false negative
    /// hides the session the user opened the menu to find.
    /// "agy" is the Antigravity CLI, and it is short on purpose: an update leaves the running
    /// binary renamed, so the founder's tab reported `agy.1788445358670789000.old` and read as a
    /// plain shell. The substring test catches both. Antigravity ships no hooks — `agy help` has
    /// no such subcommand — so naming it is all Chute can honestly do: it will sit under
    /// "Running — no status" until Antigravity has something to report.
    public static let knownAgents = ["claude", "codex", "cursor", "gemini", "aider", "agy"]

    public static func agentName(in processes: String) -> String? {
        knownAgents.filter { processes.contains($0) }.max { $0.count < $1.count }
    }

    // `project(fromWindowName:)` used to live here. DELETED — its body lives on, verbatim, as
    // `ProjectName.titleHead`, which is where `parse` above now gets its last-resort fallback.
    // One derivation, in one file, is the whole point of ProjectName.swift; keeping a second copy
    // here just because this was its original address would have defeated that.
}

/// Whether the app owning this bundle executable path is running.
///
/// A substring match against the FULL executable path, NOT pgrep: macOS reports a bundled app's
/// `comm` as its FULL executable path, so `pgrep -x Terminal` never matches Terminal.app and
/// discovery would throw .notRunning forever. Verified on macOS 14.6: pgrep finds nothing, the
/// real path lists /System/Applications/Utilities/Terminal.app/Contents/MacOS/Terminal.
/// Takes the path fragment it checks so later adapters (iTerm2, Ghostty, Warp) ask about
/// their own app rather than silently receiving Terminal's answer.
///
/// THE `ps -Ao comm` FORK, DELETED — the exact bug `ProcessMetrics.listing()` (see that file's
/// header) already fixed once, still sitting here. Measured 2026-09-09 in
/// `Scripts/bench.swift`: `discover()` was paying 102 ms for THIS call alone, on top of the
/// ~200 ms AppleScript round-trip it precedes — every menu open, before a single window was even
/// asked about. See docs/specs/PERFORMANCE.md.
///
/// `proc_listallpids` + `proc_pidpath`, not `ProcessMetrics.listing()`: that call is scoped to
/// OUR OWN uid (deliberately — see its own header, "another user's processes were never ours to
/// report"), and this check has to see root's launchd too — `TerminalParseSuite` pins exactly
/// that ("a process that is always running is detected"). `proc_pidpath` is the one primitive
/// here that CROSSES the ownership boundary — `ProcessIdentity.executablePath`'s own header
/// verifies it resolves root's launchd for a non-root reader — so `allPIDs()` (every pid on the
/// machine, no uid filter) is the right pairing, not a scoped listing.
///
/// Measured: ~2 ms for ~600 pids on this machine, against the 102 ms it replaces.
public func isAppRunning(bundleExecutable fragment: String) -> Bool {
    ProcessMetrics.allPIDs().contains { pid in
        ProcessIdentity.executablePath(pid)?.contains(fragment) ?? false
    }
}
