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
/// wrong answer — is the trial row shown on day 10? does the Basket appear when empty? — it
/// is answered here, where a test can ask it too.
///
/// AppKit specifics that carry no decision stay in the renderer: images, targets, selectors, and
/// the alternate-item modifier masks. A node says "this row is a session command of kind
/// copyResume"; the renderer knows that means ⌥⇧.
public enum StatusMenu {

    /// What a row does when clicked. An enum rather than a selector so the model stays free of
    /// AppKit — and so a test can assert that the trial row opens the licence pane rather than
    /// merely that a row with some title exists.
    public enum Command: String, Sendable, Equatable {
        case focusSession
        case sessionCommand
        case openLicenseSettings
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
        /// A macOS section header. Carries its own count, which is part of what it says.
        case header(count: Int)
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

        public init(_ kind: Kind, _ title: String, toolTip: String? = nil, payload: String? = nil) {
            self.kind = kind; self.title = title; self.toolTip = toolTip; self.payload = payload
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
                             trial: TrialState,
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

        // ── THE PAID BODY ───────────────────────────────────────────────────────────────────
        //
        // /buy sells four things and three of them used to keep working forever after the trial
        // ended — the page describing a product the build does not deliver. What a lapsed trial
        // still gets, deliberately: Settings, Report a Problem, Quit, and a plain statement that
        // the CLI does all of this for free. Nobody is trapped, and the open-core promise is kept
        // at the exact moment it would be easiest to break.
        guard trial.isUnlocked else {
            out.append(MenuNode(.command(.openLicenseSettings), "Trial ended — Buy Chute, $19 once"))
            out.append(MenuNode(.note,
                                "The chute CLI is still free — chute sessions, focus, ports",
                                toolTip: "The command line tool is MIT and never expires. The app "
                                       + "buys you the Finder menu and this switcher, not the "
                                       + "ability to do these things."))
            out.append(.separator())
            out.append(contentsOf: standardItems(trial: trial, unlocked: false,
                                                 recent: [], recentTokens: 0,
                                                 notificationsDenied: notificationsDenied))
            return out
        }

        if let problem {
            out.append(MenuNode(.command(.openAutomationSettings),
                                "Cannot read Terminal — click to fix", toolTip: problem))
            out.append(.separator())
        }

        // ── ONE FLAT LIST OF TERMINALS, AND NO STATE ────────────────────────────────────
        //
        // There were four groups here — "Waiting for You", "Working", "Running — no status" and
        // "Idle" — and a nag row above them. The founder asked for them gone, twice, and he is
        // right: a status Chute cannot always know is a status it should not always claim. The
        // hooks report at turn boundaries and nothing reports at all for an agent that ships no
        // hooks, so any session can sit in a state that stopped being true hours ago. On
        // 2026-09-04 that produced `Working (7)` over seven sessions, none of them working.
        //
        // What is left is what Chute can see for itself at the moment the menu opens: which
        // project, which agent, and what that terminal is costing. Click a row, that terminal
        // comes forward. The hooks still earn their keep — the session id is what makes
        // "Copy Resume Command", "Continue in tmux" and "Copy Cost So Far" possible — they just
        // no longer put a word on the screen that nothing can stand behind.
        //
        // Sorted by project, then tty, so the list does not reshuffle between two openings.
        // It used to be ordered by urgency, and urgency is exactly what is gone.
        for s in sessions.sorted(by: {
            ($0.project.lowercased(), $0.tty) < ($1.project.lowercased(), $1.tty)
        }) {
            out.append(contentsOf: rows(for: s, loadFor: loadFor,
                                        sessionCommands: sessionCommands, colorFor: colorFor,
                                        detailFor: detailFor))
        }
        if !sessions.isEmpty { out.append(.separator()) }

        if sessions.isEmpty && problem == nil {
            out.append(MenuNode(.note, "No terminal sessions"))
            out.append(.separator())
        }

        out.append(contentsOf: standardItems(trial: trial, unlocked: true,
                                             recent: recent, recentTokens: recentTokens,
                                             notificationsDenied: notificationsDenied))
        return out
    }

    /// One session: the row itself, then its ⌥ alternates.
    static func rows(for s: Session,
                     loadFor: (String) -> SessionLoad,
                     sessionCommands: (Session) -> [(kind: String, title: String)],
                     colorFor: (String) -> String,
                     detailFor: (Session) -> String) -> [MenuNode] {
        let hex = colorFor(s.project)
        // No "waited 4m" any more: it only ever appeared for `.blocked` and `.waiting`, which are
        // states Chute no longer claims. What stays is what is true when the menu opens.
        let load = loadFor(s.tty)
        let prefix = "\(s.project)   \(detailFor(s))"
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
    static func standardItems(trial: TrialState, unlocked: Bool,
                              recent: [ContextBuffer.Entry], recentTokens: Int,
                              notificationsDenied: Bool) -> [MenuNode] {
        var out: [MenuNode] = []
        if unlocked {
            // BASKET FIRST, THEN LOCAL SERVERS. It used to sit below Local Servers as a submenu,
            // where the owner reported "no row at all" — not because a submenu hides its count
            // (the title reads "Basket  (n)" without hovering, same as before), but because that
            // position is easy to scroll past on a long menu. Read where it is read.
            out.append(contentsOf: basket(recent, tokens: recentTokens))
            out.append(MenuNode(.servers, "Local Servers"))
        } else {
            // AN EXPIRED TRIAL MAKES BOTH VANISH SILENTLY, which to the user is indistinguishable
            // from "empty" — the same false signal this whole spec exists to stop. The gate itself
            // is unchanged: nothing here unlocks either section, it only says why they are gone.
            out.append(MenuNode(.note, "Local Servers and the Context Basket are behind the licence"))
        }
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

        // Nothing at all once it is paid for: an app that keeps mentioning payment after the
        // payment is nagging its own customer.
        if let label = Trial.menuLabel(trial) {
            out.append(MenuNode(.command(.openLicenseSettings), label))
        }
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
