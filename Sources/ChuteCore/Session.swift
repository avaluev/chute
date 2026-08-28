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
    /// WHICH agent, when one is running: "claude", "codex", "cursor", "gemini", "aider".
    /// nil is a plain shell. This used to be a Bool — the adapter matched the name out of the
    /// process list and then threw it away, so the menu could say a session was an agent but
    /// never which one, and the "Claude Code" on screen was the terminal window TITLE leaking
    /// through: a string Chute did not derive and cannot rely on.
    public let agent: String?
    public let busy: Bool
    public let state: SessionState
    public let since: Date?
    /// The agent's own session id, when the hook has been updated to emit it. nil is the normal
    /// case for anyone still running an older snippet, and every reader must cope with that.
    public let sessionID: String?
    /// Where the session is working. From the hook, never guessed from the window title.
    public let cwd: String?

    /// Whether ANY agent is running. Kept so every existing call site reads the same, and so the
    /// two can never disagree with each other.
    public var isAgent: Bool { agent != nil }

    public init(key: String, kind: TerminalKind, windowID: Int, tabIndex: Int,
                tty: String, project: String, title: String, agent: String?,
                busy: Bool, state: SessionState, since: Date?,
                sessionID: String? = nil, cwd: String? = nil) {
        self.key = key; self.kind = kind; self.windowID = windowID
        self.tabIndex = tabIndex; self.tty = tty; self.project = project
        self.title = title; self.agent = agent; self.busy = busy
        self.state = state; self.since = since
        self.sessionID = sessionID; self.cwd = cwd
    }

    /// "/dev/ttys004" and "ttys004" both normalise to "ttys004".
    public static func normalise(tty: String) -> String {
        tty.hasPrefix("/dev/") ? String(tty.dropFirst(5)) : tty
    }

    public static func makeKey(kind: TerminalKind, windowID: Int, tty: String) -> String {
        "\(kind.rawValue):\(windowID):\(normalise(tty: tty))"
    }
}
