import Foundation
import ChuteCore

func glyphSuite() {
    T.suite("StateResolver") {
        let now = Date(timeIntervalSince1970: 1_756_219_200)
        let fresh = HookRecord(tty: "ttys004", state: .blocked, timestamp: now.addingTimeInterval(-60))
        let stale = HookRecord(tty: "ttys004", state: .blocked, timestamp: now.addingTimeInterval(-7 * 3600))

        T.eq(StateResolver.resolve(hook: fresh, isAgent: true, now: now),
             .blocked, "a fresh hook is the only thing that can name a state")

        // THE 2026-09-04 BUG. Both of these used to fall through to the title glyph, which Claude
        // Code writes and never clears — three sessions whose hooks said `waiting` at 02:06, 02:34
        // and 03:10 still carried a working glyph at 10:37, so the menu said `Working (7)`.
        T.eq(StateResolver.resolve(hook: stale, isAgent: true, now: now),
             .unknown, "a hook older than six hours is ignored, and nothing replaces it")

        let future = HookRecord(tty: "ttys004", state: .blocked,
                                timestamp: now.addingTimeInterval(3600))
        T.eq(StateResolver.resolve(hook: future, isAgent: true, now: now),
             .unknown, "a future-dated hook (clock skew) is ignored, never trusted forever")

        // THE BADGE. `.waiting` is what puts a number on the menu bar icon, so guessing it here
        // was Chute telling the founder someone needed them when nothing had said so.
        T.eq(StateResolver.resolve(hook: nil, isAgent: true, now: now),
             .unknown, "an agent that has reported nothing is unknown, never 'waiting for you'")

        // And the other row from that screenshot: a tab with no agent, running something —
        // Terminal calls it busy, which is not the same as an agent working.
        T.eq(StateResolver.resolve(hook: nil, isAgent: false, now: now),
             .idle, "a tab running node or vim is not an agent working")

        // The staleness edge, both sides of it.
        let justInside = HookRecord(tty: "t", state: .waiting, timestamp: now.addingTimeInterval(-6 * 3600 + 1))
        let justOutside = HookRecord(tty: "t", state: .waiting, timestamp: now.addingTimeInterval(-6 * 3600))
        T.eq(StateResolver.resolve(hook: justInside, isAgent: true, now: now), .waiting,
             "one second inside the window still counts")
        T.eq(StateResolver.resolve(hook: justOutside, isAgent: true, now: now), .unknown,
             "exactly at the window it does not")
    }
}
