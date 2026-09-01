import Foundation

/// How a session is described to a person.
///
/// It lives here, not in the menu, for two reasons: it is pure string work with no AppKit in it,
/// and wording is the part of this product most likely to be wrong — so it must be testable.
public enum SessionPhrasing {
    /// "3h" told you a number and left you to guess what it counted. These read as a sentence:
    /// "waiting 3 hours for you". Hours and minutes are spelled out because a menu is read, not
    /// parsed — abbreviations belong in a table.
    public static func waitedFor(_ since: Date?) -> String {
        guard let since else { return "waiting for you" }
        let minutes = Int(Date().timeIntervalSince(since) / 60)
        switch minutes {
        case ..<1:   return "just asked you"
        case 1:      return "waiting 1 minute for you"
        case ..<60:  return "waiting \(minutes) minutes for you"
        case ..<120: return "waiting 1 hour for you"
        default:     return "waiting \(minutes / 60) hours for you"
        }
    }

    /// The product's name for an agent, from the process name Terminal reports.
    ///
    /// "claude" is the executable; "Claude Code" is what it is called. Anything not in this table
    /// is title-cased rather than guessed at, so a new agent appears as itself on the day it is
    /// added to `TerminalAppAdapter.knownAgents` and not a release later.
    public static func agentLabel(_ agent: String) -> String {
        switch agent {
        case "claude": return "Claude Code"
        case "codex":  return "Codex"
        case "cursor": return "Cursor"
        case "gemini": return "Gemini"
        case "aider":  return "aider"          // it spells itself lowercase
        default:       return agent.prefix(1).uppercased() + agent.dropFirst()
        }
    }

    /// EFFORT IS ONLY WORTH SAYING WHEN IT IS NOT THE DEFAULT. A word that appears on every row
    /// is furniture; "high" on the one session running high is information.
    public static let unremarkableEffort = "medium"

    /// What a session IS, for the middle of its row: the agent, the model it is on, and the effort
    /// if that is worth a word. Everything is optional because everything can be unknown — an
    /// older hook gives no session id, so there is no transcript and therefore no model, and the
    /// honest row names the agent alone rather than filling the gap with the window title.
    public static func detail(agent: String?, transcript: AgentTranscript?) -> String {
        guard let agent else { return "no agent running" }
        var parts = [agentLabel(agent)]
        if let model = AgentTranscript.displayModel(transcript?.model) { parts.append(model) }
        if let effort = transcript?.effort, effort != unremarkableEffort { parts.append(effort) }
        return parts.joined(separator: " · ")
    }

    /// "just now", "3 min", "2 h", "yesterday". Short, because it sits at the end of a menu row
    /// beside something more important than itself.
    public static func ago(_ date: Date, now: Date = Date()) -> String {
        let seconds = Int(now.timeIntervalSince(date))
        switch seconds {
        case ..<45:      return "just now"
        case ..<3600:    return "\(max(1, seconds / 60)) min"
        case ..<86_400:  return "\(seconds / 3600) h"
        case ..<172_800: return "yesterday"
        default:         return "\(seconds / 86_400) days"
        }
    }
}
