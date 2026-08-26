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
        guard isProcessRunning("Terminal") else {
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

/// Whether a process with this exact name is running. Deliberately takes the name it checks:
/// TerminalAdapter is a protocol so iTerm2/Ghostty/Warp adapters can follow, and each must be
/// able to ask about ITS OWN process rather than silently receiving Terminal.app's answer.
public func isProcessRunning(_ processName: String) -> Bool {
    !Shell.run("pgrep", ["-x", processName]).out
        .trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
}
