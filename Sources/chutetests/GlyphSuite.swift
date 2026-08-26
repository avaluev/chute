import Foundation
import ChuteCore

func glyphSuite() {
    T.suite("StateResolver") {
        let now = Date(timeIntervalSince1970: 1_756_219_200)
        let fresh = HookRecord(tty: "ttys004", state: .blocked, timestamp: now.addingTimeInterval(-60))
        let stale = HookRecord(tty: "ttys004", state: .blocked, timestamp: now.addingTimeInterval(-7 * 3600))

        T.eq(StateResolver.resolve(hook: fresh, title: "✳ anything", busy: true, isAgent: true, now: now),
             .blocked, "a fresh hook beats the title and the busy flag")

        T.eq(StateResolver.resolve(hook: stale, title: "plain", busy: true, isAgent: true, now: now),
             .working, "a hook older than six hours is ignored")

        T.eq(StateResolver.resolve(hook: nil, title: "✳ refactoring", busy: true, isAgent: true, now: now),
             .working, "known glyph resolves without a hook")

        T.eq(StateResolver.resolve(hook: nil, title: "☂ unknown glyph", busy: true, isAgent: true, now: now),
             .working, "unknown glyph falls through to the busy flag")

        T.eq(StateResolver.resolve(hook: nil, title: "no glyph", busy: false, isAgent: true, now: now),
             .waiting, "an idle agent is waiting for you")

        T.eq(StateResolver.resolve(hook: nil, title: "-zsh", busy: false, isAgent: false, now: now),
             .idle, "a plain shell is idle, never 'waiting'")

        T.eq(StateResolver.resolve(hook: nil, title: "-zsh", busy: true, isAgent: false, now: now),
             .working, "a busy shell is working")

        T.ok(GlyphTable.state(fromTitle: "✳ x") != nil, "✳ is a known glyph")
        T.ok(GlyphTable.state(fromTitle: "◑ x") != nil, "◑ is a known glyph")
        T.ok(GlyphTable.state(fromTitle: "hello") == nil, "plain text has no glyph")
        T.ok(GlyphTable.state(fromTitle: "") == nil, "empty title is nil, not a crash")
    }
}
