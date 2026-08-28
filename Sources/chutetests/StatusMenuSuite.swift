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

        T.ok(titles(licensed).contains { $0.contains("Waiting for You") },
             "a licensed menu shows the sessions that want you")
        T.no(titles(expired).contains { $0.contains("Waiting for You") },
             "an expired trial does not — the switcher is what was bought")
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

        // ── IDLE COLLAPSES PAST THREE ───────────────────────────────────────────────────────
        //
        // On a machine with eleven terminals open, the sessions you never act on push the group
        // you actually opened the menu for off the top.
        let threeIdle = (1...3).map { session("p\($0)", .idle, tty: "ttys00\($0)") }
        let fiveIdle  = (1...5).map { session("p\($0)", .idle, tty: "ttys00\($0)") }
        let flat = StatusMenu.model(sessions: threeIdle, trial: .licensed(email: "a@b.c"))
        let rolled = StatusMenu.model(sessions: fiveIdle, trial: .licensed(email: "a@b.c"))
        T.eq(flat.filter { if case .session = $0.kind { return true }; return false }.count, 3,
             "three idle terminals are listed in place")
        T.ok(find(rolled, "5 idle terminals") != nil, "five collapse into one row")
        T.eq(rolled.filter { if case .session = $0.kind { return true }; return false }.count, 0,
             "and none of them is left at the top level")
        if case .submenu(let kids)? = find(rolled, "5 idle terminals")?.kind {
            T.eq(kids.filter { if case .session = $0.kind { return true }; return false }.count, 5,
                 "all five are still reachable, one level down")
        } else {
            T.ok(false, "the collapsed row owns a submenu")
        }

        // ── RECENT COPIES — THE BUG THAT PROMPTED ALL OF THIS ───────────────────────────────
        //
        // "It is a shit hardcode. It never works." Clicking a row re-recorded the replay under
        // the HUD's confirmation wording, so the list filled with rows reading "Copied" and, at
        // ten kept, evicted everything real. ContextBuffer now refuses to file text it already
        // holds; this asserts the MENU half — that the section is absent when empty, that its
        // count matches its contents, and that the rows carry the words the entries were
        // delivered under rather than a verb.
        let empty = StatusMenu.model(sessions: live, trial: .licensed(email: "a@b.c"), recent: [])
        T.no(titles(empty).contains { $0.contains("Recent Copies") },
             "Recent Copies is absent entirely when there is nothing in it")

        let dir = NSTemporaryDirectory() + "chute-menu-\(UUID().uuidString)"
        defer { try? FileManager.default.removeItem(atPath: dir) }
        let buf = ContextBuffer(directory: dir)
        buf.record("the patch", label: "Diff · what the agent changed")
        buf.record("/a/b.ts", label: "2 full paths")
        buf.record("the patch", label: "Copied")          // the replay that used to file a row
        let entries = buf.entries().reversed().map { $0 }

        let withCopies = StatusMenu.model(sessions: live, trial: .licensed(email: "a@b.c"),
                                          recent: entries)
        let parent = find(withCopies, "Recent Copies")
        T.ok(parent != nil, "and present once there is something to put back")
        T.eq(parent?.title, "Recent Copies  (2)",
             "counting the two DISTINCT things copied, not the three record calls")

        guard case .submenu(let rows)? = parent?.kind else {
            T.ok(false, "Recent Copies owns a submenu"); return
        }
        let rowTitles = rows.filter { $0.kind != .separator }.map(\.title)
        T.ok(rowTitles.contains { $0.contains("Diff · what the agent changed") },
             "a row is named for what it IS")
        T.no(rowTitles.contains { $0.hasPrefix("Copied") },
             "and never for the confirmation that announced it")
        T.ok(rowTitles.contains { $0.contains("Copy All 2 Together") },
             "the count in Copy All matches the rows above it")
        T.ok(rowTitles.contains("Clear"), "and it can be emptied")
        // Every entry row must carry which entry it is, or clicking it can only guess.
        let copyRows = rows.filter { $0.kind == .command(.bufferCopyOne) }
        T.eq(copyRows.count, 2, "one row per held entry")
        T.no(copyRows.contains { $0.payload == nil },
             "and each names the entry it would put back")

        // ── ORDER ───────────────────────────────────────────────────────────────────────────
        //
        // Most urgent first. A menu that lists idle shells above an agent that is blocked on you
        // has buried the only row that needed you.
        let mixed = StatusMenu.model(
            sessions: [session("c", .idle, tty: "ttys003"),
                       session("a", .blocked, tty: "ttys001"),
                       session("b", .working, tty: "ttys002")],
            trial: .licensed(email: "a@b.c"))
        let headers = mixed.compactMap { node -> String? in
            if case .header = node.kind { return node.title }
            return nil
        }
        T.eq(headers, ["Waiting for You", "Working", "Idle"],
             "the groups run most urgent first")
        T.ok(find(mixed, "Quit Chute") != nil, "and Quit is last")
        T.eq(mixed.last?.title, "Quit Chute", "literally last, so it is where the hand expects it")

        // A group with nothing in it is not announced. An empty "Working (0)" is a row that costs
        // a glance and says nothing.
        let onlyIdle = StatusMenu.model(sessions: [session("c", .idle, tty: "ttys003")],
                                        trial: .licensed(email: "a@b.c"))
        T.no(onlyIdle.contains { if case .header = $0.kind { return $0.title == "Working" }; return false },
             "an empty group is not given a header")

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

        // ── THE BADGE CANNOT WORK AND NOTHING SAYS SO ───────────────────────────────────────
        //
        // `updateBadgeFromHooks` reports 0 when no hook record has EVER existed — the same
        // picture as "nothing needs you". The two must not be conflated: a quiet machine with
        // hooks wired has zero CURRENT records constantly, and that is not a problem.
        let needsHook = StatusMenu.model(sessions: live, trial: .licensed(email: "a@b.c"),
                                         hasHookRecords: false)
        let hookRow = find(needsHook, "Agent status needs a hook")
        T.ok(hookRow != nil, "live sessions with zero hook records EVER get one explaining row")
        T.eq(hookRow?.kind, .command(.copyHooksSnippet), "and clicking it copies the snippet")
        T.eq(hookRow?.payload, HookInstaller.manualSnippet(),
             "carrying exactly what chute hooks snippet would print")

        T.no(titles(StatusMenu.model(sessions: live, trial: .licensed(email: "a@b.c")))
                .contains { $0.contains("Agent status needs a hook") },
             "the default (hooks presumed wired) shows nothing extra")
        T.no(titles(StatusMenu.model(sessions: [], trial: .licensed(email: "a@b.c"),
                                     hasHookRecords: false))
                .contains { $0.contains("Agent status needs a hook") },
             "and neither does an empty machine — nothing running, nothing to explain")

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
