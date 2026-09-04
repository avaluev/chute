import Foundation

/// WHAT A SESSION IS DOING — and the two things that were being mistaken for evidence of it.
///
/// A terminal cannot see inside an agent. Only the agent can say what it is doing, and the only
/// way it says so is a hook. Everything else Chute can observe is a proxy, and on 2026-09-04 both
/// proxies in use here were shown to be wrong at the same time — the founder's menu read
/// `Working (7)` with not one of the seven actually working:
///
///   · **Terminal's `busy` flag** means "a process other than the shell is running in this tab".
///     vim, a build, node, an agent, anything. One of the seven rows was `38.LifespanOS · no agent
///     running` — a tab with no agent in it at all, filed under Working because something was
///     running in it.
///
///   · **The glyph Claude Code writes into the title** (`✳`, `◑`, …) does not survive as evidence,
///     because Claude Code does not CLEAR it when the turn ends. Three sessions whose own hook
///     records said `waiting` at 02:06, 02:34 and 03:10 still carried a working glyph in their
///     titles at 10:37. The glyph proves Claude Code once wrote that title; it says nothing about
///     now. It was consulted whenever the hook record aged out, which is exactly when it is at its
///     most stale — so a session left overnight read "working" forever.
///
/// So: a hook, or nothing. `.unknown` is a real answer and the menu prints it under its own
/// header. A guess dressed as a state is worse than a blank, because `.waiting` puts a number on
/// the menu bar badge, and a badge that cries wolf is a badge you stop reading.
public enum StateResolver {
    /// A hook older than this is treated as dead, so a crashed session — or a tty number reused by
    /// a new tab — cannot pin a permanent false "waiting" badge on the menu bar.
    public static let staleAfterDefault: TimeInterval = 6 * 3600

    public static func resolve(hook: HookRecord?,
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
        return isAgent ? .unknown : .idle
    }
}
