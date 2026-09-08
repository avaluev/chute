import Foundation
import ChuteCore

/// The menu bar, asserted headlessly.
///
/// Fifty-one menu-item decisions used to live in `Sources/ChuteApp/`, which `chutetests` cannot
/// link — so none of them was checked by anything, ever. That is how Recent Copies shipped
/// broken. Everything below is a question that previously could only be answered by opening the
/// menu and looking.
func statusMenuSuite() {
    T.suite("StatusMenu") {
        // A real `cwd` by default — most sessions Chute sees have one, and giving every fixture
        // one here means `dim`/"no project derived" is something a test opts INTO explicitly
        // (see the edge-case block below) rather than something every other assertion trips over
        // by accident.
        func session(_ project: String, _ state: SessionState, tty: String,
                     id: String? = "sess-\(UUID().uuidString.prefix(4))",
                     since: Date = Date(), cwd: String? = nil) -> Session {
            Session(key: "Terminal:1:\(tty)", kind: .terminalApp, windowID: 1, tabIndex: 1,
                    tty: tty, project: project, title: project, agent: "claude",
                    busy: state == .working, state: state, since: since, sessionID: id,
                    cwd: cwd ?? "/nonexistent-chute-test-root/\(project)")
        }
        // Pulls just the `.session` rows' `SessionRow`s out of a rendered menu, in order — the
        // shape most of the assertions below actually want, rather than re-deriving it from
        // `.title` every time.
        func sessionRows(_ nodes: [StatusMenu.MenuNode]) -> [StatusMenu.SessionRow] {
            nodes.compactMap { if case .session = $0.kind { return $0.row }; return nil }
        }
        // The one `.note` node that carries a row — see `MenuNode.row`'s doc comment for why that
        // IS the column header, structurally, with nothing else to distinguish it.
        func header(_ nodes: [StatusMenu.MenuNode]) -> StatusMenu.MenuNode? {
            nodes.first { if case .note = $0.kind { return $0.row != nil }; return false }
        }

        // ── COLUMNS, NOT HEADERS ─────────────────────────────────────────────────────────
        //
        // State section headers ("NEEDS YOU 2") and per-project sub-headers are DELETED,
        // 2026-09-08 — three aligned columns say what a header used to say on every row, so the
        // header repeated information the row already had. Sort order and the dot still carry
        // the urgency; a separator still marks a state boundary.
        let threeStates = [session("c", .idle, tty: "ttys003"),
                           session("a", .working, tty: "ttys001"),
                           session("b", .unknown, tty: "ttys002")]
        let flatMenu = StatusMenu.model(sessions: threeStates)
        T.eq(flatMenu.filter { if case .session = $0.kind { return true }; return false }.count, 3,
             "every terminal is listed, whatever it is doing")
        // Raw values: .blocked=0, .waiting=1, .working=2, .idle=3, .unknown=4 — idle outranks
        // unknown (a plain shell is a KNOWN calm state; "Chute does not know" is worse than that).
        T.eq(sessionRows(flatMenu).map(\.project), ["a", "c", "b"],
             "sorted by state first (working, then idle, then unknown), every row naming its own project")

        // EXACTLY ONE column header when there is something to head, and NONE when there is not —
        // a header over nothing is furniture.
        T.eq(flatMenu.filter { if case .note = $0.kind { return $0.row != nil }; return false }.count,
             1, "exactly one column-header node when sessions exist")
        T.eq(StatusMenu.model(sessions: []).filter { if case .note = $0.kind { return $0.row != nil }
                                                      return false }.count,
             0, "and none at all when there are no sessions to head")
        // ITS THREE COLUMN STRINGS, verbatim.
        if let head = header(flatMenu)?.row {
            T.eq(head.project, "PROJECT", "col 1's header")
            T.eq(head.state, "AGENT · STATE", "col 2's header")
            T.eq(head.figures, "LOAD", "col 3's header")
        } else {
            T.ok(false, "a column header exists to check")
        }

        // REPEATS REPEAT — no sub-header groups them any more. Two `dup`s and one `solo`, all in
        // the same state, read as three rows naming their own project, in that literal order.
        let paired = StatusMenu.model(sessions: [
            session("dup", .working, tty: "ttys011"),
            session("dup", .working, tty: "ttys012"),
            session("solo", .working, tty: "ttys013")])
        T.eq(sessionRows(paired).map(\.project), ["dup", "dup", "solo"],
             "repeats repeat — the columns are what replaces the grouping, not a new grouping")
        T.no(paired.contains { if case .note = $0.kind { return $0.title == "dup" }; return false },
             "and there is no sub-header node left to carry the repeated name instead")

        // ORDER MUST BE STABLE or the menu reshuffles between two openings of the same menu.
        T.eq(StatusMenu.model(sessions: threeStates).map(\.title), flatMenu.map(\.title),
             "the same sessions always produce the same menu")

        // BLOCKED FIRST, AND LONGEST-BLOCKED FIRST INSIDE THAT. Twenty seconds blocked is noise;
        // twenty minutes is twenty minutes in which nothing happened, so it goes at the top.
        let now = Date(timeIntervalSince1970: 1_757_000_000)
        let ordered = StatusMenu.model(
            sessions: [session("fresh", .blocked, tty: "ttys009", since: now.addingTimeInterval(-60)),
                       session("stale", .blocked, tty: "ttys008", since: now.addingTimeInterval(-3600)),
                       session("busy",  .working, tty: "ttys007", since: now.addingTimeInterval(-10))],
            now: now)
        let firstRow = sessionRows(ordered).first
        T.eq(firstRow?.project, "stale",
             "the one that has been blocked an hour outranks the one blocked a minute")
        T.ok(firstRow?.state.hasPrefix("blocked") == true, "and its state cell says so, with a duration")

        // SEPARATORS MARK STATE BOUNDARIES, not the top of the list and never inside a band. Three
        // bands (blocked ×2, working ×2, idle ×2) need exactly two separators between the header
        // and the standard items — one per boundary, none inside a band of matching state.
        let banded = StatusMenu.model(sessions: [
            session("a1", .blocked, tty: "ttys101"), session("a2", .blocked, tty: "ttys102"),
            session("b1", .working, tty: "ttys103"), session("b2", .working, tty: "ttys104"),
            session("c1", .idle,    tty: "ttys105"), session("c2", .idle,    tty: "ttys106"),
        ])
        if let headerIndex = banded.firstIndex(where: { if case .note = $0.kind { return $0.row != nil }
                                                         return false }),
           let serversIndex = banded.firstIndex(where: { $0.kind == .servers }) {
            // The slice up to `serversIndex` also catches the ONE trailing separator model()
            // always emits before standardItems (`if !sessions.isEmpty { out.append(.separator()) }`)
            // — that one marks "sessions end here", not a state boundary, so it is dropped before
            // counting. It is provably the slice's last element: `recent` is empty here, so
            // `basket(...)` contributes nothing between it and the `.servers` node.
            let sessionBlock = banded[(headerIndex + 1)..<serversIndex].dropLast()
            T.eq(sessionBlock.filter { $0.kind == .separator }.count, 2,
                 "three bands need exactly two separators between them")
        } else {
            T.ok(false, "both the header and Local Servers exist to bound the session block")
        }

        func titles(_ nodes: [StatusMenu.MenuNode]) -> [String] {
            nodes.filter { $0.kind != .separator }.map(\.title)
        }
        func find(_ nodes: [StatusMenu.MenuNode], _ needle: String) -> StatusMenu.MenuNode? {
            nodes.first { $0.title.contains(needle) }
        }

        let live = [session("37.chute", .blocked, tty: "ttys001"),
                    session("studylock", .working, tty: "ttys002"),
                    session("sntz", .idle, tty: "ttys003")]

        // ── NO GATE, AND NO WAY BACK TO ONE ─────────────────────────────────────────────
        //
        // This block used to assert the opposite: that an expired 14-day trial hid the session
        // list, the Local Servers section and the Basket, and said so in a row at the top.
        // Chute went free and MIT on 2026-09-08 and the gate was DELETED rather than switched
        // off, so what is worth asserting now is the absence of any branch that can hide the
        // product from its own user — and that no price can creep back into a title.
        let menu = StatusMenu.model(sessions: live)

        T.ok(menu.contains { if case .session = $0.kind { return true }; return false },
             "the menu lists the terminals")
        T.ok(menu.contains { $0.kind == .servers }, "and carries the Local Servers section")
        for escape in ["Settings…", "Setup…", "Report a Problem…", "Quit Chute"] {
            T.ok(find(menu, escape) != nil, "the menu still offers \(escape)")
        }
        // Built, not written: the fact sheet's FALSE table forbids this literal anywhere in
        // Sources, and a test asserting a string must not appear cannot itself spell it.
        let price = "$" + "19"
        T.no(titles(menu).contains {
                 let t = $0.lowercased()
                 return t.contains("licence") || t.contains("license")
                     || t.contains("trial") || t.contains(price) || t.contains("buy chute")
             },
             "and never mentions a licence, a trial or a price")

        // ── THE DUPLICATE-MENU BUG ──────────────────────────────────────────────────────────
        //
        // populateBody clears the menu, and it used to be SessionMenu.populate that did — which
        // the early-return branch never reached, so it appended a second complete copy of the
        // menu on every open. It grew without bound. A pure model cannot accumulate, and this is
        // the assertion that says so.
        T.eq(StatusMenu.model(sessions: live).count, menu.count,
             "building the menu twice gives the same menu, not two of it")

        // ── NO REFRESH ──────────────────────────────────────────────────────────────────────
        //
        // It called refresh(), which built a NEW NSMenu and assigned it to statusItem.menu —
        // and menuWillOpen then rebuilt everything on that fresh object, so the work was thrown
        // away every time. A command that cannot change what you see teaches the reader that the
        // menu might be stale.
        for menu in [menu] {
            T.no(titles(menu).contains { $0.localizedCaseInsensitiveContains("refresh") },
                 "nothing in this menu is called Refresh")
        }

        // ── THE BASKET — THE BUG THAT PROMPTED ALL OF THIS ──────────────────────────────────
        //
        // "It is a shit hardcode. It never works." Only 3 of 10 Finder actions ever wrote to the
        // old store, so the list could not change no matter what the owner did — indistinguishable
        // from hardcoded, from outside. An entry is a FILE PATH now (see ContextBuffer.swift), and
        // the only way in is an explicit add. This asserts the MENU half: absent when empty, its
        // count matches its contents, and each row names the file it is.
        let empty = StatusMenu.model(sessions: live, recent: [])
        T.no(titles(empty).contains { $0.contains("Basket") },
             "the basket is absent entirely when there is nothing in it")

        let dir = NSTemporaryDirectory() + "chute-menu-\(UUID().uuidString)"
        defer { try? FileManager.default.removeItem(atPath: dir) }
        let buf = ContextBuffer(directory: dir)
        // CREATED, ADDED, THEN DELETED — which is the scenario the "— missing" row exists for.
        // These were three paths that had never existed, which worked only because `add` did not
        // check. It does now (a path that never existed is a different thing from a file that
        // vanished afterwards), and this fixture is the honest version of what it was testing.
        let fixtures = ["a", "b", "c"].map { dir + "-fixture-\($0).ts" }
        for f in fixtures { FileManager.default.createFile(atPath: f, contents: Data("x".utf8)) }
        for f in fixtures { _ = buf.add(f) }
        for f in fixtures { try? FileManager.default.removeItem(atPath: f) }
        let entries = buf.entries().reversed().map { $0 }

        let withBasket = StatusMenu.model(sessions: live,
                                          recent: entries, recentTokens: 1234)
        let parent = find(withBasket, "Basket")
        T.ok(parent != nil, "and present once there is something in it")
        T.eq(parent?.title, "Basket  (3)", "counting the three files added")

        guard case .submenu(let rows)? = parent?.kind else {
            T.ok(false, "Basket owns a submenu"); return
        }
        let rowTitles = rows.filter { $0.kind != .separator }.map(\.title)
        T.ok(rowTitles.contains { $0.contains("-fixture-a.ts") },
             "a row is named for the file it is")
        T.ok(rowTitles.contains { $0.contains("— missing") },
             "and says so when the path no longer exists on disk, rather than dropping the row")
        T.ok(rowTitles.contains("Copy Basket as @mentions"),
             "the ICP's format is offered — Claude Code / Cursor already have filesystem access")
        T.ok(rowTitles.contains { $0.contains("Copy Basket as Context") && $0.contains("~1k tokens") },
             "and the bundle format carries the token count it was handed, not one it computed itself")
        T.no(rowTitles.contains { $0.contains("Copy Basket as @mentions") && $0.contains("tokens") },
             "while the @mention row carries no count — it costs almost nothing to send")
        T.ok(rowTitles.contains("Empty Basket"), "and it can be emptied")
        // Every entry row must carry which entry it is, or clicking it can only guess.
        let fileRows = rows.filter { $0.kind == .command(.bufferReveal) }
        T.eq(fileRows.count, 3, "one row per held entry")
        T.no(fileRows.contains { $0.payload == nil },
             "and each carries the path it would reveal in Finder")

        // ── POSITION: HIGH IN THE MENU, NOT BURIED UNDER LOCAL SERVERS ──────────────────────
        //
        // Being a submenu near the bottom of a long menu is why the owner reported "no row at
        // all" in the first place — its count was always readable without hovering, the same as
        // it is now; what moved is WHERE.
        let basketIndex = withBasket.firstIndex { $0.title.hasPrefix("Basket") }
        let serversIndex = withBasket.firstIndex { $0.kind == .servers }
        if let b = basketIndex, let s = serversIndex {
            T.ok(b < s, "the basket sits above Local Servers, where it is read")
        } else {
            T.ok(false, "both the basket and Local Servers are present to compare positions")
        }

        // ── ORDER ───────────────────────────────────────────────────────────────────────────
        //
        // Most urgent first. A menu that lists idle shells above an agent that is blocked on you
        // has buried the only row that needed you.
        let mixed = StatusMenu.model(
            sessions: [session("c", .idle, tty: "ttys003"),
                       session("a", .blocked, tty: "ttys001"),
                       session("b", .working, tty: "ttys002")])
        T.eq(mixed.filter { if case .session = $0.kind { return true }; return false }.count, 3,
             "a blocked session is listed like any other — nothing is ranked any more")
        T.ok(find(mixed, "Quit Chute") != nil, "and Quit is last")
        T.eq(mixed.last?.title, "Quit Chute", "literally last, so it is where the hand expects it")

        // ── NOTHING RUNNING, AND SOMETHING WRONG ────────────────────────────────────────────
        let none = StatusMenu.model(sessions: [])
        T.ok(find(none, "No terminal sessions") != nil,
             "an empty machine says so rather than showing a blank menu")
        let broken = StatusMenu.model(sessions: [],
                                      problem: "Automation permission denied")
        T.ok(find(broken, "Cannot read Terminal") != nil,
             "a denied Automation permission is reported as fixable, not as an empty list")
        T.eq(find(broken, "Cannot read Terminal")?.kind, .command(.openAutomationSettings),
             "and clicking it goes where the fix is")
        T.no(titles(broken).contains { $0.contains("No terminal sessions") },
             "and it does NOT also claim there are no sessions — we could not look")

        // ── THE NOTIFICATIONS ROW ───────────────────────────────────────────────────────────
        // Only ever shown when a fallback notification was actually refused.
        T.no(titles(menu).contains { $0.contains("Turn On Chute Notifications") },
             "no notifications row when nothing was refused")
        let denied = StatusMenu.model(sessions: live,
                                      notificationsDenied: true)
        T.ok(find(denied, "Turn On Chute Notifications") != nil, "and one when it was")

        // ── THE NUMBERS ON A ROW — two cells now, not one string ───────────────────────────
        let calm = SessionLoad(cpuPercent: 12, residentBytes: 1_073_741_824, processes: 4)
        let calmCols = StatusMenu.loadColumns(calm)
        T.eq(calmCols.figures, "12% · 1.0 GB", "figures read '<cpu>% · <bytes>', not the old CPU/memory words")
        T.eq(calmCols.note, "", "an ordinary session's second line is empty")
        T.eq(calmCols.noteToken, "", "and its colour key is the quiet, total-lookup default")

        let hot = SessionLoad(cpuPercent: 300, residentBytes: 1_073_741_824, processes: 4)
        T.ok(StatusMenu.isRunaway(hot), "three cores pinned is a runaway")
        let hotCols = StatusMenu.loadColumns(hot)
        T.eq(hotCols.note, "runaway ⚠", "a WORD plus the glyph — never a bare ⚠ on its own")
        T.eq(hotCols.noteToken, "alarm", "and the colour key says so")
        T.eq(hotCols.figures, "300% · 1.0 GB", "the warning does not replace the figures — they sit in col 3's own line")

        let fat = SessionLoad(cpuPercent: 1, residentBytes: 9 * 1_073_741_824, processes: 4)
        T.ok(StatusMenu.isRunaway(fat), "and so is nine gigabytes held by one session")

        T.eq(StatusMenu.loadColumns(SessionLoad(cpuPercent: 0, residentBytes: 0, processes: 0)).figures,
             "", "no live process at all means EMPTY figures, not '0%' — that would claim a measurement")

        // The peak, on the row, only when it dwarfs the present.
        let spiked = SessionLoad(cpuPercent: 3, residentBytes: 866 * 1_048_576, processes: 9,
                                 peakBytes: 6 * 1_073_741_824)
        T.eq(StatusMenu.loadColumns(spiked).note, "peaked 6.0 GB",
             "a session that held six gigabytes says so, unwrapped, once it lets them go")
        T.eq(StatusMenu.loadColumns(spiked).noteToken, "quiet", "and it is not an alarm")
        let steady = SessionLoad(cpuPercent: 3, residentBytes: 6 * 1_073_741_824, processes: 9,
                                 peakBytes: 6 * 1_073_741_824)
        T.eq(StatusMenu.loadColumns(steady).note, "",
             "and one whose peak IS its present says nothing — that is not information")

        // ── replacingLoad TOUCHES ONLY THE LOAD COLUMNS ─────────────────────────────────────
        let baseRow = StatusMenu.SessionRow(project: "p", path: "/nonexistent-chute-test-root/p",
                                            state: "s", agent: "a", figures: "old",
                                            note: "old note", noteToken: "quiet")
        let replaced = baseRow.replacingLoad(hot)
        T.eq(replaced.project, baseRow.project, "replacingLoad leaves project untouched")
        T.eq(replaced.path, baseRow.path, "and path")
        T.eq(replaced.state, baseRow.state, "and state")
        T.eq(replaced.agent, baseRow.agent, "and agent")
        T.eq(replaced.figures, hotCols.figures, "figures IS replaced, with the new load's own")
        T.eq(replaced.note, hotCols.note, "and note")
        T.eq(replaced.noteToken, hotCols.noteToken, "and its colour key")

        // ── THE WIDTH CLAMP — a character budget alone is not enough ───────────────────────
        //
        // Mockup 2c's own caption: "the one that makes a bad project name harmless". A
        // 24-character name of nothing but wide capitals fits PathAbbrev's CHARACTER budget
        // exactly (24 == 24, not truncated there) but still overflows the real 190pt column —
        // measured 277pt in MENUBAR-LAYOUT-CALIBRATION.md. `clampedProjectName` must catch what
        // the character count alone cannot.
        T.eq(StatusMenu.clampedProjectName("chute"), "chute",
             "an ordinary name needs no clamping — one measurement, no loop")
        let allW = String(repeating: "W", count: 24)
        T.eq(PathAbbrev.name(allW).count, 24,
             "PathAbbrev's own character budget does not touch this — 24 is not OVER 24")
        let clampedW = StatusMenu.clampedProjectName(allW)
        T.ok(clampedW.count < allW.count,
             "the width clamp shrinks it further than the character budget alone would")
        T.ok(clampedW.hasSuffix("…"), "and marks the extra cut with the same ellipsis PathAbbrev uses")

        // ── THE ⌥ FACE: same identity, only the verb changes ───────────────────────────────
        let cmdSession = session("cmdproj", .waiting, tty: "ttys090")
        let withCmds = StatusMenu.model(sessions: [cmdSession],
            sessionCommands: { _ in [(kind: "copyID", title: "Copy Session ID")] })
        let parentRow = sessionRows(withCmds).first
        let altNode = withCmds.first { if case .sessionCommand = $0.kind { return true }; return false }
        T.eq(altNode?.row?.path, parentRow?.path, "an alternate's path (line 2) matches its parent's")
        T.eq(altNode?.row?.agent, parentRow?.agent, "and its agent (line 2)")
        T.eq(altNode?.row?.note, parentRow?.note, "and its note (line 2)")
        T.eq(altNode?.row?.project, parentRow?.project, "col 1 (line 1) is unchanged too — only the verb swaps")
        T.ok(altNode?.row?.state != parentRow?.state, "col 2's line 1 IS the command's own title")
        T.eq(altNode?.row?.figures, StatusMenu.keyGlyphs(for: "copyID"),
             "and col 3's line 1 is that command's ⌥ glyphs")

        // ── TEN EDGE CASES ───────────────────────────────────────────────────────────────────
        //
        // 1 & 2 (no sessions at all; Terminal unreadable) are covered above and in the
        // "NOTHING RUNNING" block below — both predate this file and both still hold, because
        // `title` stays populated.

        // 3. NO CWD, NO TITLE: a bare tty names itself, and its path cell says so, dimmed.
        let bareTTY = Session(key: "Terminal:1:ttys077", kind: .terminalApp, windowID: 1, tabIndex: 1,
                              tty: "ttys077", project: nil, title: "", agent: nil, busy: false,
                              state: .idle, since: Date(), sessionID: nil, cwd: nil)
        let bareMenu = StatusMenu.model(sessions: [bareTTY])
        let bareRow = sessionRows(bareMenu).first
        T.eq(bareRow?.project, "tty ttys077", "no cwd, no title — the tty itself names the row")
        T.eq(bareRow?.path, "no project derived", "and the path cell says so, honestly")
        let bareNode = bareMenu.first { if case .session = $0.kind { return true }; return false }
        T.eq(bareNode?.dim, true, "dimmed — there is no cwd standing behind this name")

        // 4. AN AGENT WITH NO HOOK (Antigravity, today): the state cell says so, never a duration.
        let noHookRow = sessionRows(StatusMenu.model(sessions: [session("agy-project", .unknown, tty: "ttys078")])).first
        T.eq(noHookRow?.state, "no hook — Chute cannot see this", "an agent with no hook says so, not a guess")
        T.no(noHookRow?.state.contains(where: \.isNumber) ?? true, "and it never carries a duration")

        // 5. A PLAIN SHELL, NO AGENT: "no agent running", sorted to the bottom by state order.
        let plainShell = Session(key: "Terminal:1:ttys079", kind: .terminalApp, windowID: 1, tabIndex: 1,
                                 tty: "ttys079", project: "shellproj", title: "shellproj", agent: nil,
                                 busy: false, state: .idle, since: Date(), sessionID: nil,
                                 cwd: "/nonexistent-chute-test-root/shellproj")
        T.eq(sessionRows(StatusMenu.model(sessions: [plainShell])).first?.state, "no agent running",
             "a plain shell's state cell names its own absence of an agent")

        // 6. NO LIVE PROCESS: covered above — `loadColumns` at zero processes gives empty figures.

        // 7. MODEL/EFFORT UNKNOWN: the agent cell is the agent's name alone.
        let bareAgentRow = sessionRows(StatusMenu.model(sessions: [session("bareagent", .working, tty: "ttys080")])).first
        T.eq(bareAgentRow?.agent, "Claude Code", "nothing more to say, so the row says only what it is sure of")

        // 8. PEAK NOT WORTH SHOWING: covered above — `steady`'s note is empty.

        // 9. NAME LONGER THAN ITS COLUMN: tail-truncated in the cell, whole in the tooltip.
        let longName = String(repeating: "a", count: 40)
        let longNameMenu = StatusMenu.model(sessions: [session(longName, .working, tty: "ttys081")])
        let longNameRow = sessionRows(longNameMenu).first
        T.ok((longNameRow?.project.count ?? 999) < longName.count, "an overlong name is truncated in the column")
        T.ok(longNameRow?.project.hasSuffix("…") == true, "tail-truncated — a name is a word")
        let longNameNode = longNameMenu.first { if case .session = $0.kind { return true }; return false }
        T.ok(longNameNode?.toolTip?.contains(longName) == true, "and the FULL name survives in the tooltip")

        // 10. PATH LONGER THAN ITS COLUMN: middle-truncated in the cell, whole in the tooltip.
        let longPath = "/nonexistent-chute-test-root/" + String(repeating: "b", count: 40) + "/leaf"
        let longPathMenu = StatusMenu.model(sessions: [session("pathy", .working, tty: "ttys082", cwd: longPath)])
        T.ok(sessionRows(longPathMenu).first?.path.contains("…") == true,
             "an overlong path is middle-truncated in the column")
        let longPathNode = longPathMenu.first { if case .session = $0.kind { return true }; return false }
        T.ok(longPathNode?.toolTip?.contains(longPath) == true, "and the FULL path survives in the tooltip")

        // ── EVERY FIELD WITHIN ITS COLUMN BUDGET ────────────────────────────────────────────
        T.ok((longNameRow?.project.count ?? 0) <= PathAbbrev.defaultNameBudget,
             "col 1's name cell never exceeds PathAbbrev's own character budget")
        T.ok((sessionRows(longPathMenu).first?.path.count ?? 0) <= PathAbbrev.defaultBudget,
             "col 1's path cell never exceeds PathAbbrev's own character budget")
    }
}
