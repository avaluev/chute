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
        func session(_ project: String, _ state: SessionState, tty: String,
                     id: String? = "sess-\(UUID().uuidString.prefix(4))") -> Session {
            Session(key: "Terminal:1:\(tty)", kind: .terminalApp, windowID: 1, tabIndex: 1,
                    tty: tty, project: project, title: project, agent: "claude",
                    busy: state == .working, state: state, since: Date(), sessionID: id)
        }
        // ── ONE FLAT LIST, NO STATE ─────────────────────────────────────────────────────
        //
        // There were four groups and a nag row. The founder asked for them gone, twice: a status
        // Chute cannot always know is a status it should not always claim, and on 2026-09-04 the
        // menu said `Working (7)` over seven sessions of which none was working.
        let threeStates = [session("c", .idle, tty: "ttys003"),
                           session("a", .working, tty: "ttys001"),
                           session("b", .unknown, tty: "ttys002")]
        let flatMenu = StatusMenu.model(sessions: threeStates, trial: .licensed(email: "a@b.c"))
        T.eq(flatMenu.filter { if case .header = $0.kind { return true }; return false }.count, 0,
             "no state headers at all — not Working, not Idle, not one of them")
        T.eq(flatMenu.filter { if case .session = $0.kind { return true }; return false }.count, 3,
             "every terminal is listed, at the top level, whatever it is doing")
        // Stable order, or the list reshuffles between two openings of the same menu.
        let projects = flatMenu.compactMap { node -> String? in
            if case .session = node.kind { return node.title.components(separatedBy: " ").first }
            return nil
        }
        T.eq(projects, ["a", "b", "c"], "sorted by project, not by urgency — urgency is gone")

        func titles(_ nodes: [StatusMenu.MenuNode]) -> [String] {
            nodes.filter { $0.kind != .separator }.map(\.title)
        }
        func find(_ nodes: [StatusMenu.MenuNode], _ needle: String) -> StatusMenu.MenuNode? {
            nodes.first { $0.title.contains(needle) }
        }

        let live = [session("37.chute", .blocked, tty: "ttys001"),
                    session("studylock", .working, tty: "ttys002"),
                    session("sntz", .idle, tty: "ttys003")]

        // ── THE TRIAL GATE ──────────────────────────────────────────────────────────────────
        //
        // /buy sells four things — the Finder menu, this switcher, the local-server list and the
        // hotkey — and three of them kept working forever after the trial ended, which is the
        // page describing a product the build does not deliver. handoff/NEXT.md asked a HUMAN to
        // verify this by hand, because nothing could reach it. Now it is four assertions.
        let licensed = StatusMenu.model(sessions: live, trial: .licensed(email: "a@b.c"))
        let expired  = StatusMenu.model(sessions: live, trial: .expired)

        T.ok(licensed.contains { if case .session = $0.kind { return true }; return false },
             "a licensed menu lists the terminals")
        T.no(expired.contains { if case .session = $0.kind { return true }; return false },
             "an expired trial lists none — the switcher is what was bought")
        T.ok(find(expired, "Trial ended — Buy Chute") != nil, "and says so, once, at the top")
        T.ok(find(expired, "chute CLI is still free") != nil,
             "and keeps the open-core promise at the moment it would be easiest to break")

        // Nobody is trapped: the ways out survive an expired trial.
        for escape in ["Settings…", "Setup…", "Report a Problem…", "Quit Chute"] {
            T.ok(find(expired, escape) != nil, "an expired trial still offers \(escape)")
        }
        // But not the paid surfaces.
        T.no(expired.contains { $0.kind == .servers },
             "the local-server list is behind the gate with everything else")

        // ── AN EXPIRED TRIAL EXPLAINS ITSELF ────────────────────────────────────────────────
        //
        // Local Servers and Recent Copies used to just vanish when `!unlocked` — indistinguishable
        // from "empty", the same false signal as everything else in this spec. The gate itself
        // must not move: still no `.servers` node above, still nothing in Recent Copies' place.
        T.ok(find(expired, "behind the licence") != nil,
             "and says WHY those two sections are gone")
        T.no(titles(licensed).contains { $0.contains("behind the licence") },
             "a paying customer is never told a section is gated")

        // ── THE TRIAL ROW, ON THE RIGHT DAYS ────────────────────────────────────────────────
        //
        // An app that keeps mentioning payment after the payment is nagging its own customer;
        // one that never mentions it lets a trial lapse in silence. Both edges asserted.
        let day10 = StatusMenu.model(sessions: live, trial: .trial(daysLeft: 10))
        let day3  = StatusMenu.model(sessions: live, trial: .trial(daysLeft: 3))
        let day1  = StatusMenu.model(sessions: live, trial: .trial(daysLeft: 1))
        T.no(titles(day10).contains { $0.hasPrefix("Trial —") },
             "on day 10 there is no trial row: nothing is wrong yet")
        T.ok(find(day3, "Trial — 3 days left") != nil, "on day 3 there is")
        T.ok(find(day1, "Trial — last day") != nil, "and the last day says so in words, not '1'")
        T.no(titles(licensed).contains { $0.hasPrefix("Trial") },
             "a paying customer is never told about a trial again")

        // ── THE DUPLICATE-MENU BUG ──────────────────────────────────────────────────────────
        //
        // populateBody clears the menu, and it used to be SessionMenu.populate that did — which
        // the expired branch returned before ever reaching, so it appended a second complete copy
        // of the menu on every open. It grew without bound, in front of the one person deciding
        // whether to pay. A pure model cannot accumulate, and this is the assertion that says so.
        T.eq(StatusMenu.model(sessions: live, trial: .expired).count, expired.count,
             "building the expired menu twice gives the same menu, not two of it")
        T.eq(StatusMenu.model(sessions: live, trial: .licensed(email: "a@b.c")).count,
             licensed.count, "and the same for a licensed one")

        // ── NO REFRESH ──────────────────────────────────────────────────────────────────────
        //
        // It called refresh(), which built a NEW NSMenu and assigned it to statusItem.menu —
        // and menuWillOpen then rebuilt everything on that fresh object, so the work was thrown
        // away every time. A command that cannot change what you see teaches the reader that the
        // menu might be stale.
        for menu in [licensed, expired, day3] {
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
        let empty = StatusMenu.model(sessions: live, trial: .licensed(email: "a@b.c"), recent: [])
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

        let withBasket = StatusMenu.model(sessions: live, trial: .licensed(email: "a@b.c"),
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
                       session("b", .working, tty: "ttys002")],
            trial: .licensed(email: "a@b.c"))
        T.eq(mixed.filter { if case .header = $0.kind { return true }; return false }.count, 0,
             "a blocked session gets no header either — nothing is ranked any more")
        T.ok(find(mixed, "Quit Chute") != nil, "and Quit is last")
        T.eq(mixed.last?.title, "Quit Chute", "literally last, so it is where the hand expects it")

        // ── NOTHING RUNNING, AND SOMETHING WRONG ────────────────────────────────────────────
        let none = StatusMenu.model(sessions: [], trial: .licensed(email: "a@b.c"))
        T.ok(find(none, "No terminal sessions") != nil,
             "an empty machine says so rather than showing a blank menu")
        let broken = StatusMenu.model(sessions: [], trial: .licensed(email: "a@b.c"),
                                      problem: "Automation permission denied")
        T.ok(find(broken, "Cannot read Terminal") != nil,
             "a denied Automation permission is reported as fixable, not as an empty list")
        T.eq(find(broken, "Cannot read Terminal")?.kind, .command(.openAutomationSettings),
             "and clicking it goes where the fix is")
        T.no(titles(broken).contains { $0.contains("No terminal sessions") },
             "and it does NOT also claim there are no sessions — we could not look")

        // ── THE NOTIFICATIONS ROW ───────────────────────────────────────────────────────────
        // Only ever shown when a fallback notification was actually refused.
        T.no(titles(licensed).contains { $0.contains("Turn On Chute Notifications") },
             "no notifications row when nothing was refused")
        let denied = StatusMenu.model(sessions: live, trial: .licensed(email: "a@b.c"),
                                      notificationsDenied: true)
        T.ok(find(denied, "Turn On Chute Notifications") != nil, "and one when it was")

        // ── THE NUMBERS ON A ROW ────────────────────────────────────────────────────────────
        let calm = SessionLoad(cpuPercent: 12, residentBytes: 1_073_741_824, processes: 4)
        T.no(StatusMenu.suffix(calm).contains("⚠"), "an ordinary session carries no warning")
        let hot = SessionLoad(cpuPercent: 300, residentBytes: 1_073_741_824, processes: 4)
        T.ok(StatusMenu.isRunaway(hot), "three cores pinned is a runaway")
        T.ok(StatusMenu.suffix(hot).contains("⚠"), "and the row says so beside the figures")
        T.ok(StatusMenu.suffix(hot).contains("300% CPU"),
             "the warning does not REPLACE the numbers — it sits next to them")
        let fat = SessionLoad(cpuPercent: 1, residentBytes: 9 * 1_073_741_824, processes: 4)
        T.ok(StatusMenu.isRunaway(fat), "and so is nine gigabytes held by one session")
        T.eq(StatusMenu.suffix(SessionLoad(cpuPercent: 0, residentBytes: 0, processes: 0)), "",
             "a session with no processes reports nothing rather than zero")

        // The peak, on the row, only when it dwarfs the present.
        let spiked = SessionLoad(cpuPercent: 3, residentBytes: 866 * 1_048_576, processes: 9,
                                 peakBytes: 6 * 1_073_741_824)
        T.ok(StatusMenu.suffix(spiked).contains("peaked 6.0 GB"),
             "a session that held six gigabytes says so after it lets them go")
        let steady = SessionLoad(cpuPercent: 3, residentBytes: 6 * 1_073_741_824, processes: 9,
                                 peakBytes: 6 * 1_073_741_824)
        T.no(StatusMenu.suffix(steady).contains("peaked"),
             "and one whose peak IS its present says nothing — that is not information")
    }
}
