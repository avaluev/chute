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
        if let hook {
            // now - timestamp goes NEGATIVE under clock skew, and a negative age would pass any
            // `age < staleAfter` test forever — pinning a dead session's state permanently.
            // A hook from the future is not fresh, it is untrustworthy: ignore it.
            let age = now.timeIntervalSince(hook.timestamp)
            if age >= 0, age < staleAfter { return hook.state }
        }
        if let glyphState = GlyphTable.state(fromTitle: title) {
            return glyphState
        }
        if busy { return .working }
        return isAgent ? .waiting : .idle
    }
}
