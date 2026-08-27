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

    public static func elide(_ s: String, _ max: Int = 34) -> String {
        guard s.count > max else { return s }
        let half = (max - 1) / 2
        return String(s.prefix(half)) + "…" + String(s.suffix(half))
    }
}
