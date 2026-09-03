import Foundation

/// The commands a single session offers, and which modifier reveals each one.
///
/// This used to live in `Sources/ChuteApp/SessionMenu.swift`, which `chutetests` cannot link —
/// so the two rules below, both of which have a wrong answer, were unreachable by any test:
///
///   1. WHICH commands a session offers. It depends on the transcript and on whether tmux is
///      installed, and offering one that cannot work puts a failing command on someone's
///      clipboard.
///   2. WHICH modifier reveals each one. AppKit shows ONE alternate per distinct modifier mask,
///      so two commands that share a mask means one of them is simply never drawn — a row that
///      exists, is correct, and cannot be reached. Nothing in the drawing code can notice that;
///      `SessionCommandsSuite` asks the table directly.
///
/// `SessionMenu` keeps only the AppKit half: turning `Modifiers` into `NSEvent.ModifierFlags`.
public enum SessionCommand {
    public enum Kind: String, Sendable, CaseIterable { case copyID, copyResume, tmux, copyCost }

    public struct Payload: Sendable {
        public let key: String
        public let kind: Kind
        public init(key: String, kind: Kind) { self.key = key; self.kind = kind }
    }

    /// A modifier set with no AppKit in it, so the table above can be linked by the suite.
    public struct Modifiers: OptionSet, Sendable, Hashable {
        public let rawValue: Int
        public init(rawValue: Int) { self.rawValue = rawValue }
        public static let option  = Modifiers(rawValue: 1 << 0)
        public static let shift   = Modifiers(rawValue: 1 << 1)
        public static let command = Modifiers(rawValue: 1 << 2)
        public static let control = Modifiers(rawValue: 1 << 3)
    }

    /// Four commands on one row means four alternates, spread across ⌥, ⌥⇧, ⌥⌘ and ⌥⌃ rather
    /// than crammed into a submenu that would cost the row its single-click focus — an NSMenuItem
    /// that owns a submenu does not fire its own action, and the hero job is *click the row, that
    /// terminal comes forward*. Every mask carries ⌥, because ⌥ is what the row's tooltip promises.
    public static func modifiers(for kind: String) -> Modifiers {
        switch Kind(rawValue: kind) {
        case .copyResume: return [.option, .shift]
        case .tmux:       return [.option, .command]
        case .copyCost:   return [.option, .control]
        default:          return [.option]
        }
    }

    /// Only what this session can actually do. A command that cannot work is not shown greyed
    /// out — it is not shown, because a disabled row still costs the reader a glance to dismiss.
    public static func available(for s: Session, transcript: AgentTranscript?,
                                 hasTmux: Bool = SessionCommand.hasTmux)
        -> [(kind: String, title: String)] {
        guard let sessionID = s.sessionID else { return [] }   // an older hook: nothing to resume
        var offers: [(kind: String, title: String)] = [(Kind.copyID.rawValue, "Copy Session ID")]

        // Only where the agent's resume syntax is actually known. Offering "Copy Resume Command"
        // for an agent we would have to guess at puts a failing command on someone's clipboard.
        if ResumeCommand.resume(agent: s.agent, sessionID: sessionID) != nil {
            offers.append((Kind.copyResume.rawValue, "Copy Resume Command"))
            if hasTmux { offers.append((Kind.tmux.rawValue, "Continue in tmux")) }
        }
        if let t = transcript,
           AgentTranscript.costLabel(output: t.outputTokens, cacheRead: t.cacheReadTokens) != nil {
            offers.append((Kind.copyCost.rawValue, "Copy Cost So Far"))
        }
        return offers
    }

    /// Checked once. `tmux` is a Homebrew install on most machines and its absence is permanent
    /// for the length of a session; offering a command that cannot run is worse than not offering.
    public static let hasTmux = Shell.which("tmux") != nil
}
