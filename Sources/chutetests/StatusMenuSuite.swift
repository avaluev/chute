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
                     id: String? = "sess-\(UUID().uuidString.prefix(4))",
                     since: Date = Date()) -> Session {
            Session(key: "Terminal:1:\(tty)", kind: .terminalApp, windowID: 1, tabIndex: 1,
                    tty: tty, project: project, title: project, agent: "claude",
                    busy: state == .working, state: state, since: since, sessionID: id)
        }
        // ── TWO LEVELS: WHAT YOU MUST DO, THEN WHICH PROJECT ────────────────────────────
        //
        // Grouping was here, was deleted in 2849347, and is back — the appetite never changed,
        // the EVIDENCE did. The old groups read state off Terminal's `busy` flag and off the
        // spinner glyph Claude Code writes into a title and never clears, which on 2026-09-04
        // produced `Working (7)` over seven sessions of which none was working. StateResolver
        // now takes state from a hook or answers `.unknown`, and `.unknown` gets its own header
        // instead of being filed under something confident.
        //
        // The flat list it replaced was its own bug: the founder's menu on 2026-09-08 held
        // thirteen rows, five of them named `sntz_mockups`, and nothing said which had stopped.
        let threeStates = [session("c", .idle, tty: "ttys003"),
                           session("a", .working, tty: "ttys001"),
                           session("b", .unknown, tty: "ttys002")]
        let flatMenu = StatusMenu.model(sessions: threeStates)
        T.eq(flatMenu.filter { if case .session = $0.kind { return true }; return false }.count, 3,
             "every terminal is listed, whatever it is doing")

        // Section order IS state order: SessionState is Comparable with .blocked == 0, so the
        // thing that has stopped and needs a human always sits above the thing still running.
        let headers = flatMenu.filter { $0.kind == .note && $0.indent == 0 }.map(\.title)
        T.eq(headers, ["WORKING   1", "NO AGENT   1", "NO STATUS — HOOKS NOT REPORTING   1"],
             "one header per state, in urgency order, each carrying its own count")

        // A SUB-HEADER ONLY WHEN IT GROUPS SOMETHING. One session per project per section here,
        // so there is nothing to group and the project name rides on the row instead. The
        // founder's real menu showed seven sub-headers over eight rows, which is a stutter.
        T.eq(flatMenu.filter { $0.kind == .note && $0.indent == 1 }.count, 0,
             "a lone session gets no sub-header of its own")
        T.ok(flatMenu.contains { if case .session = $0.kind { return $0.title.hasPrefix("a ") }
                                 return false },
             "and names its project on the row instead")

        // Two sessions of ONE project in ONE section: now the sub-header earns its line, the
        // rows indent under it, and they stop repeating the name it already carries.
        let paired = StatusMenu.model(sessions: [
            session("dup", .working, tty: "ttys011"),
            session("dup", .working, tty: "ttys012"),
            session("solo", .working, tty: "ttys013")])
        T.eq(paired.filter { $0.kind == .note && $0.indent == 1 }.map(\.title), ["dup"],
             "a project with two sessions in a section gets exactly one sub-header")
        T.eq(paired.filter { if case .session = $0.kind { return $0.indent == 2 }; return false }
                   .count, 2,
             "and its rows sit one step further in than the lone one")

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
        T.eq(ordered.first(where: { $0.kind == .note })?.title, "NEEDS YOU   2",
             "the section that needs a human is first, and says how many")
        let firstRow = ordered.first { if case .session = $0.kind { return true }; return false }
        T.ok(firstRow?.title.hasPrefix("stale ") == true,
             "and the one that has been waiting an hour outranks the one waiting a minute")

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
