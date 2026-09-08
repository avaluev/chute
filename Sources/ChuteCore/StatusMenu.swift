import Foundation

/// EVERY DECISION THE MENU BAR MAKES, AS DATA A TEST CAN READ.
///
/// ── WHY THIS EXISTS ─────────────────────────────────────────────────────────────────────────
///
/// `Package.swift` declares the test target against `ChuteCore` only, so the eleven files in
/// `Sources/ChuteApp/` cannot be linked by `chutetests` and have zero coverage. Fifty-one
/// menu-item decisions lived in there, unreachable by any gate.
///
/// That is not a theoretical gap. It is how Recent Copies shipped broken: clicking a row filed a
/// new buffer entry under the confirmation's wording, so ten clicks left ten rows reading
/// "Copied" and evicted the ten real things the list held. Using the feature destroyed it, and
/// nothing could have caught that, because nothing could see the menu.
///
/// The pattern being copied already works two files away: `ChuteActions.rows()` is pure data in
/// ChuteCore, and `FinderActionsSuite` asserts its titles, its count and that no two rows share
/// an icon — headlessly, on every build.
///
/// ── THE DIVISION ────────────────────────────────────────────────────────────────────────────
///
/// `StatusMenu.model(...)` decides WHAT is in the menu, in what order, with what titles.
/// `SessionMenu` turns that into `NSMenu` and decides NOTHING. If a question has a right and a
/// wrong answer — does the Basket appear when empty? which row is first? — it
/// is answered here, where a test can ask it too.
///
/// AppKit specifics that carry no decision stay in the renderer: images, targets, selectors, and
/// the alternate-item modifier masks. A node says "this row is a session command of kind
/// copyResume"; the renderer knows that means ⌥⇧.
public enum StatusMenu {

    /// What a row does when clicked. An enum rather than a selector so the model stays free of
    /// AppKit — and so a test can assert that a row runs the command it claims rather than
    /// merely that a row with some title exists.
    public enum Command: String, Sendable, Equatable {
        case focusSession
        case sessionCommand
        case openAutomationSettings
        case openNotificationSettings
        case reportProblem
        case openSettings
        case openSetup
        case quit
        case bufferReveal
        case bufferMentions
        case bufferFlush
        case bufferClear
    }

    public enum Kind: Sendable, Equatable {
        case separator
        /// A terminal session. `key` is `Session.key`; the renderer focuses it.
        ///
        /// `tty` and `prefix` are carried for the live refresh: while the menu is open a timer
        /// re-samples every two seconds and retitles each row in place. Only the SUFFIX changes —
        /// the description half cannot change while a menu is being looked at — so the prefix is
        /// computed once, here, rather than rebuilt from a transcript on every tick.
        case session(key: String, tty: String, colorHex: String, prefix: String)
        /// The ⌥ face of a session row.
        case sessionCommand(key: String, kind: String, colorHex: String)
        /// Anything that just runs a command.
        case command(Command)
        /// Text with no action — a statement, not a button.
        case note
        /// A row that owns a submenu. Renders as a parent with children and no action of its own.
        case submenu([MenuNode])
        /// The local-servers section, expanded by the renderer from live port data. Present as a
        /// node so its POSITION is asserted here even though its contents are not.
        case servers
    }

    public struct MenuNode: Sendable, Equatable {
        public let kind: Kind
        public let title: String
        public let toolTip: String?
        /// Carried on buffer rows so the renderer knows which entry to put back.
        public let payload: String?
        /// How far in to draw the row. The renderer assigns it to `NSMenuItem.indentationLevel`
        /// unconditionally, so nesting costs the renderer no branch — which matters, because
        /// Scripts/check-untested-logic.sh counts every branch in ChuteApp against a baseline
        /// and the whole grouping had to fit inside a budget of zero.
        public let indent: Int

        public init(_ kind: Kind, _ title: String, toolTip: String? = nil, payload: String? = nil,
                    indent: Int = 0) {
            self.kind = kind; self.title = title; self.toolTip = toolTip; self.payload = payload
            self.indent = indent
        }

        public static func separator() -> MenuNode { MenuNode(.separator, "") }
    }

    /// IDLE COLLAPSES PAST THREE. These are the sessions you never act on, and on a machine with
    /// eleven terminals open they push the group you actually opened the menu for off the top.

    /// The whole menu, in order.
    ///
    /// `sessionCommands` is injected rather than computed: which commands a session offers
    /// depends on its transcript and on whether tmux is installed, and neither belongs in a pure
    /// function. The renderer supplies it; a test supplies a stub.
    public static func model(sessions: [Session],
                             now: Date = Date(),
                             problem: String? = nil,
                             recent: [ContextBuffer.Entry] = [],
                             /// The basket's "Copy Basket as Context" row needs a token count, and
                             /// getting one means reading files off disk — a side effect this
                             /// function otherwise never has. The caller does that read once and
                             /// hands back a number rather than letting this function go and
                             /// read files, which would make it untestable for the sake of a row.
                             recentTokens: Int = 0,
                             notificationsDenied: Bool = false,
                             loadFor: (String) -> SessionLoad = { _ in
                                 SessionLoad(cpuPercent: 0, residentBytes: 0, processes: 0) },
                             sessionCommands: (Session) -> [(kind: String, title: String)] = { _ in [] },
                             colorFor: (String) -> String = SessionColor.hex(forProject:),
                             detailFor: @escaping (Session) -> String = {
                                 SessionPhrasing.detail(agent: $0.agent, transcript: nil)
                             }) -> [MenuNode] {
        var out: [MenuNode] = []


        if let problem {
            out.append(MenuNode(.command(.openAutomationSettings),
                                "Cannot read Terminal — click to fix", toolTip: problem))
            out.append(.separator())
        }

        // ── TWO LEVELS: WHAT YOU MUST DO ABOUT IT, THEN WHICH PROJECT ───────────────────
        //
        // A FLAT LIST WAS THE PROBLEM. The founder's own menu on 2026-09-08 held thirteen rows,
        // five of them named `sntz_mockups`, and not one of them said which session had stopped.
        // Every fact was there except the only one that makes you act.
        //
        // Grouping was here once and was deleted in 2849347, correctly: the state came from
        // Terminal's `busy` flag and from the spinner glyph Claude Code writes into the title,
        // and neither survives as evidence — the glyph is never CLEARED, so a session left
        // overnight read "working" forever. That produced `Working (7)` over seven sessions with
        // none of them working, and a group header that lies is worse than no header.
        //
        // What changed is the evidence, not the appetite. StateResolver now takes state from a
        // hook or returns `.unknown`, and `.unknown` gets its own header rather than being
        // quietly filed under something confident. So the grouping comes back, over a source
        // that can say "I do not know".
        //
        // Order inside a section is oldest-first: the session that has been blocked longest is
        // the one costing you the most, and it sits at the top where your eye already is.
        let ordered = sessions.sorted {
            ($0.state, $0.since ?? .distantFuture, $0.project.lowercased(), $0.tty)
                < ($1.state, $1.since ?? .distantFuture, $1.project.lowercased(), $1.tty)
        }
        var lastState: SessionState? = nil
        var lastProject: String? = nil
        for s in ordered {
            if s.state != lastState {
                out.append(.separator())
                out.append(MenuNode(.note, sectionTitle(s.state, in: ordered)))
                lastState = s.state
                lastProject = nil
            }
            if s.project != lastProject {
                out.append(MenuNode(.note, s.project, indent: 1))
                lastProject = s.project
            }
            out.append(contentsOf: rows(for: s, now: now, loadFor: loadFor,
                                        sessionCommands: sessionCommands, colorFor: colorFor,
                                        detailFor: detailFor))
        }
        if !sessions.isEmpty { out.append(.separator()) }

        if sessions.isEmpty && problem == nil {
            out.append(MenuNode(.note, "No terminal sessions"))
            out.append(.separator())
        }

        out.append(contentsOf: standardItems(recent: recent, recentTokens: recentTokens,
                                             notificationsDenied: notificationsDenied))
        return out
    }

    /// The header for a state's section, with how many sessions are under it.
    ///
    /// "NEEDS YOU", not "BLOCKED": the header's job is to say what you must DO, and the reader
    /// scanning a menu bar drop-down is deciding where to click, not reading a state machine.
    /// `.unknown` gets its own header rather than being filed under something confident —
    /// an agent that ships no hooks (Antigravity, today) is genuinely unknown, and saying so is
    /// the whole reason the grouping could come back at all.
    static func sectionTitle(_ state: SessionState, in sessions: [Session]) -> String {
        let n = sessions.filter { $0.state == state }.count
        let name: String
        switch state {
        case .blocked: name = "NEEDS YOU"
        case .waiting: name = "READY FOR A PROMPT"
        case .working: name = "WORKING"
        case .idle:    name = "NO AGENT"
        case .unknown: name = "NO STATUS — HOOKS NOT REPORTING"
        }
        return "\(name)   \(n)"
    }

    /// One session: the row itself, then its ⌥ alternates.
    static func rows(for s: Session,
                     now: Date = Date(),
                     loadFor: (String) -> SessionLoad,
                     sessionCommands: (Session) -> [(kind: String, title: String)],
                     colorFor: (String) -> String,
                     detailFor: (Session) -> String) -> [MenuNode] {
        let hex = colorFor(s.project)
        // "blocked 22 min" IS THE PRODUCT. This was deleted with the grouping in 2849347 and it
        // comes back with it, for the same reason: the duration is the whole signal. Blocked for
        // twenty seconds is noise you would never have noticed; blocked for twenty minutes is
        // twenty minutes in which nothing at all happened. `Session.since` has been populated
        // since TerminalAppAdapter landed and had no reader outside the tests until now.
        //
        // The project name is dropped from the row: the sub-header directly above it already
        // says which project this is, and repeating it is what made thirteen rows unreadable.
        let load = loadFor(s.tty)
        let held = SessionPhrasing.held(s.state, since: s.since, now: now)
        let prefix = held.isEmpty ? detailFor(s) : "\(detailFor(s))   \(held)"
        var out: [MenuNode] = [
            MenuNode(.session(key: s.key, tty: s.tty, colorHex: hex, prefix: prefix),
                     prefix + suffix(load),
                     toolTip: "\(s.title) · terminal \(s.tty) · click to bring it forward"
                            + "\n Hold ⌥ for this session's commands.")
        ]
        for c in sessionCommands(s) {
            out.append(MenuNode(.sessionCommand(key: s.key, kind: c.kind, colorHex: hex),
                                "\(s.project)   \(c.title)"))
        }
        return out
    }

    /// Everything below the sessions, which is the same on every open.
    static func standardItems(recent: [ContextBuffer.Entry], recentTokens: Int,
                              notificationsDenied: Bool) -> [MenuNode] {
        var out: [MenuNode] = []
        // BASKET FIRST, THEN LOCAL SERVERS. It used to sit below Local Servers as a submenu,
        // where the owner reported "no row at all" — not because a submenu hides its count
        // (the title reads "Basket  (n)" without hovering, same as before), but because that
        // position is easy to scroll past on a long menu. Read where it is read.
        out.append(contentsOf: basket(recent, tokens: recentTokens))
        out.append(MenuNode(.servers, "Local Servers"))
        out.append(.separator())

        // Only ever set when a fallback notification was actually REFUSED — which means the HUD
        // could not draw, so this really is the last channel left.
        if notificationsDenied {
            out.append(MenuNode(.command(.openNotificationSettings), "Turn On Chute Notifications…",
                                toolTip: "Chute normally confirms an action on screen. When it "
                                       + "cannot — no display attached — a notification is the "
                                       + "only way left to tell you."))
        }
        out.append(MenuNode(.command(.openSetup), "Setup…"))
        out.append(MenuNode(.command(.reportProblem), "Report a Problem…"))
        out.append(MenuNode(.command(.openSettings), "Settings…"))
        out.append(.separator())

        // NO "REFRESH NOW". It built a NEW NSMenu and assigned it to statusItem.menu, and
        // menuWillOpen then fired on that fresh object and rebuilt everything again — so the work
        // was discarded every time. It could not have done anything: the menu is already rebuilt
        // on every open and the badge is driven by a DispatchSource on the hook directory. A
        // command that cannot change what you see teaches the reader that the menu might be stale.
        out.append(MenuNode(.command(.quit), "Quit Chute"))
        return out
    }

    /// HIDDEN ENTIRELY WHEN EMPTY, so it costs a reader nothing on day one — and so that the
    /// "(n)" in its title is never a lie. The entries arrive newest-first.
    ///
    /// Rewritten from `recentCopies`: an entry is a FILE PATH now, not a copy of its content (see
    /// `ContextBuffer.swift`), so a row is the file's own name and folder, its payload is the
    /// path itself, and clicking it reveals the file in Finder rather than replaying a clipboard
    /// write. `@mentions` comes first — the ICP's format — `Context` second, carrying the token
    /// count only the bundle needs.
    static func basket(_ entries: [ContextBuffer.Entry], tokens: Int) -> [MenuNode] {
        guard !entries.isEmpty else { return [] }
        var children: [MenuNode] = entries.map {
            MenuNode(.command(.bufferReveal),
                     "\($0.preview)      \(SessionPhrasing.ago($0.date))",
                     toolTip: "Reveal this file in Finder.", payload: $0.path)
        }
        children.append(.separator())
        children.append(MenuNode(.command(.bufferMentions), "Copy Basket as @mentions"))
        children.append(MenuNode(.command(.bufferFlush),
                                 "Copy Basket as Context   (\(TokenEstimate.badge(tokens)))"))
        children.append(MenuNode(.command(.bufferClear), "Empty Basket"))
        return [MenuNode(.submenu(children), "Basket  (\(entries.count))")]
    }

    // ── THE NUMBERS ON A ROW ────────────────────────────────────────────────────────────────

    /// Percent of ONE core, the way `ps` and Activity Monitor report it, so 300 means three cores
    /// pinned. A coding agent doing that for as long as it takes you to open a menu is stuck in a
    /// loop, not thinking. The memory figure catches the other failure: an agent that has run for
    /// hours and is now the reason everything else is swapping.
    public static let runawayCPUPercent = 250.0
    public static let runawayBytes: UInt64 = 8 * 1_073_741_824   // 8 GB

    public static func isRunaway(_ load: SessionLoad) -> Bool {
        load.cpuPercent >= runawayCPUPercent || load.residentBytes >= runawayBytes
    }

    /// What a row says about its own cost: the numbers, plus a ⚠ when they are alarming. The
    /// warning is not a substitute for the figures — it sits beside them. "8.4 GB" tells you how
    /// much; "⚠" tells you that is the one to look at.
    public static func suffix(_ load: SessionLoad) -> String {
        let label = load.label
        guard !label.isEmpty else { return "" }
        return "   \(label)\(isRunaway(load) ? "  ⚠" : "")"
    }
}
