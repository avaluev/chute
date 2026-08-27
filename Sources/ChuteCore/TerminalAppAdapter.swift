import Foundation

/// Terminal.app via AppleScript. No Accessibility permission, no process-table polling.
/// Fields are separated by ASCII US (0x1F) and records by RS (0x1E) because window titles
/// legitimately contain commas, dashes, quotes and emoji.
public struct TerminalAppAdapter: TerminalAdapter {
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
    static let discoveryScript = """
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

    public func discover(hooks: [String: HookRecord], now: Date) throws -> [Session] {
        guard isAppRunning(bundleExecutable: "Terminal.app/Contents/MacOS/Terminal") else {
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

/// Whether the app owning this bundle executable path is running.
///
/// Deliberately `ps -Ao comm` and a substring match, NOT pgrep: macOS reports a bundled app's
/// `comm` as its FULL executable path, so `pgrep -x Terminal` never matches Terminal.app and
/// discovery would throw .notRunning forever. Verified on macOS 14.6: pgrep finds nothing,
/// `ps -Ao comm` lists /System/Applications/Utilities/Terminal.app/Contents/MacOS/Terminal.
/// Takes the path fragment it checks so later adapters (iTerm2, Ghostty, Warp) ask about
/// their own app rather than silently receiving Terminal's answer.
public func isAppRunning(bundleExecutable fragment: String) -> Bool {
    Shell.run("ps", ["-Ao", "comm"]).out.contains(fragment)
}
