import Foundation
import ChuteCore

/// THE FOUR IDENTICAL ROWS. Four Antigravity tabs open on one repo drew four rows reading the
/// same project over the same path, and the founder called them invisible — correctly: nothing on
/// screen distinguished one from another. These are the rules that make line 2 differ.
func sessionTitleSuite() {
    T.suite("SessionTitle") {
        // ── WHAT SURVIVES ───────────────────────────────────────────────────────────────────
        T.eq(SessionTitle.meaningful("✳ Gate fixtures and routes cleanup", project: "sntz_mockups"),
             "Gate fixtures and routes cleanup",
             "a real session title survives, WITHOUT the agent's spinner glyph: `✳` renders as a "
             + "green emoji blob an inch from Chute's own state square, saying the same thing worse")
        T.eq(SessionTitle.meaningful("  provenance-first-osint-audit  ", project: nil),
             "provenance-first-osint-audit", "surrounding whitespace is not part of a title")

        // ── WHAT DOES NOT ───────────────────────────────────────────────────────────────────
        // Antigravity sets a literal "Terminal" on every tab it opens and never revisits it, which
        // is why its sessions were the ones reported: the title field was populated, and useless.
        T.eq(SessionTitle.meaningful("Terminal", project: "39.IMDB_Parsing"), nil,
             "Antigravity's default title names a category, not a session")
        T.eq(SessionTitle.meaningful("✳ Claude Code", project: "sntz_mockups"), nil,
             "the glyph is stripped BEFORE the generic test, or a spinner would smuggle it past")
        T.eq(SessionTitle.meaningful("◑ CLAUDE CODE", project: nil), nil,
             "and the test is case-insensitive")
        T.eq(SessionTitle.meaningful("", project: nil), nil, "an unset title is not a label")
        T.eq(SessionTitle.meaningful("✳ ", project: nil), nil,
             "nor is a title that is nothing but a glyph")
        T.eq(SessionTitle.meaningful("37.chute", project: "37.chute"), nil,
             "a title that repeats the project says nothing the row does not already say")

        // ── THE ROW IT FEEDS ────────────────────────────────────────────────────────────────
        // The whole point, asserted end to end: two sessions in ONE directory, one agent, must
        // not produce two identical line 2s.
        func row(_ tty: String, _ title: String) -> StatusMenu.SessionRow? {
            let s = Session(key: "k\(tty)", kind: .terminalApp, windowID: 1, tabIndex: 1, tty: tty,
                            project: "39.IMDB_Parsing", title: title, agent: "agy", busy: false,
                            state: .unknown, since: nil, cwd: "/Users/x/39.IMDB_Parsing")
            return StatusMenu.model(sessions: [s], detailFor: { _ in "Antigravity" })
                .compactMap { if case .session = $0.kind { return $0.row }; return nil }.first
        }
        T.eq(row("ttys011", "Terminal")?.path, "terminal ttys011",
             "a junk title falls back to the tty — weaker than a title, still unique, still what "
             + "`chute focus` takes")
        T.ok(row("ttys011", "Terminal")?.path != row("ttys012", "Terminal")?.path,
             "THE BUG: two agy tabs in one directory no longer draw the same row twice")
        let long = "◑ provenance-first osint audit of every source"
        T.ok(row("ttys014", long)?.path.hasSuffix("…") == true,
             "a long title is cut to the same budget the path it replaced had — tail-truncated, "
             + "because a title is words and a reader recognises words by their start")
        T.ok((row("ttys014", long)?.path.count ?? 0) <= PathAbbrev.defaultBudget,
             "and never overruns it")
    }
}
