import Foundation
// AppKit, IN CHUTECORE — the same call `MenuBarMark.swift` already made. `NSFont`/
// `NSAttributedString` are how `clampedProjectName` below MEASURES a name in the real row font
// instead of only counting its characters — and the reason this lives here rather than in
// ChuteApp is exactly why MenuBarMark does the same thing: `chutetests` links ChuteCore, so a
// decision that needs AppKit to be MADE correctly still has to live somewhere a test can reach it.
import AppKit

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
        /// `tty` is carried for the live refresh: while the menu is open a timer re-samples every
        /// two seconds and rebuilds the row's attributed title from `MenuNode.row` with fresh
        /// load figures — see `SessionMenu.LiveVitals`. The row itself (project, path, state,
        /// agent, load) lives on `MenuNode.row`, not here, so there is exactly one place a test —
        /// or the live-refresh timer — reads it from.
        case session(key: String, tty: String, colorHex: String)
        /// The ⌥ face of a session row. Its `MenuNode.row` is the parent row with line 1's verb
        /// swapped for the command's own title — see `rows(for:)`.
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
        /// How far in to draw the row. Nesting is gone now that the two-level state/project
        /// grouping is deleted, so every session row is 0 — kept as a field rather than deleted
        /// outright because the renderer still assigns it to `NSMenuItem.indentationLevel`
        /// unconditionally, at no branch cost.
        public let indent: Int
        /// The six-cell, two-line row a `.session`, `.sessionCommand`, or the one column-header
        /// `.note` carries — `nil` for everything else. The renderer resolves this with `.map`
        /// rather than an `if`, which is what keeps SessionMenu.swift inside its 15-decision-point
        /// budget: a `.note` with a row IS the column header, structurally, with no flag needed to
        /// say so.
        public let row: SessionRow?
        /// Whether col 1 (the project name and the path beneath it) reads secondary rather than
        /// bold — true exactly when there is no `cwd` to stand behind the name. Decided here,
        /// where `StatusMenuSuite` can read it, rather than as an `if s.cwd == nil` inside
        /// SessionMenu.swift, which is exactly the kind of decision Phase 1's whole split exists
        /// to keep out of an untestable target.
        public let dim: Bool

        public init(_ kind: Kind, _ title: String, toolTip: String? = nil, payload: String? = nil,
                    indent: Int = 0, row: SessionRow? = nil, dim: Bool = false) {
            self.kind = kind; self.title = title; self.toolTip = toolTip; self.payload = payload
            self.indent = indent; self.row = row; self.dim = dim
        }

        public static func separator() -> MenuNode { MenuNode(.separator, "") }
    }

    /// THE COLUMN MODEL. `MenuNode.title` cannot express a three-column, two-line row — this can.
    /// Every string here arrives ALREADY TRUNCATED to its column's budget: that is the one thing
    /// that can silently wreck this layout, and only ChuteCore is linked by `chutetests`, so it is
    /// the only place it can be tested (see this file's own header comment on the split).
    public struct SessionRow: Sendable, Equatable {
        public let project, path: String      // col 1, line 1 / line 2
        public let state, agent: String       // col 2, line 1 / line 2
        public let figures, note: String      // col 3, line 1 / line 2
        /// "alarm" | "quiet" | "" — the renderer's colour key for `note`, a total dictionary
        /// lookup so a runaway session's warning and an ordinary peak note never share a branch.
        public let noteToken: String

        public init(project: String, path: String, state: String, agent: String,
                    figures: String, note: String, noteToken: String) {
            self.project = project; self.path = path; self.state = state; self.agent = agent
            self.figures = figures; self.note = note; self.noteToken = noteToken
        }

        /// `LiveVitals` rewrites ONLY the load columns, every two seconds while the menu is open —
        /// the description half of a row cannot change while it is being looked at, so this is
        /// the one place a row ever mutates, and it touches exactly the three fields that can.
        public func replacingLoad(_ load: SessionLoad) -> SessionRow {
            let (figures, note, noteToken) = StatusMenu.loadColumns(load)
            return SessionRow(project: project, path: path, state: state, agent: agent,
                              figures: figures, note: note, noteToken: noteToken)
        }
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
                             /// Whether Chute's hooks are installed in ~/.claude/settings.json.
                             /// Injected, not read here: `model` does no I/O, and the answer
                             /// decides what an `.unknown` Claude Code row is allowed to blame.
                             hooksWired: Bool = true,
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

        // ── COLUMNS, NOT HEADERS ─────────────────────────────────────────────────────────
        //
        // "NEEDS YOU (2)" section headers and per-project sub-headers are DELETED, 2026-09-08,
        // along with the whole flat-list-of-spaces row they were compensating for. Three aligned
        // columns say, on every row, what a header used to say once per group — which state,
        // which agent, which load — so the header was repeating information the row already had.
        // Sort order and the dot still carry the urgency (see `stateToken` below); a separator
        // still marks where one state's rows end and the next begins.
        //
        // Order is oldest-first WITHIN a state: the session that has been blocked longest is the
        // one costing you the most, and it sits at the top where your eye already is. Sorting on
        // the project name too, ahead of tty, only breaks ties when everything else is equal —
        // `?? ""` because `project` is the derivation, which can come back with nothing.
        let ordered = sessions.sorted {
            ($0.state, $0.since ?? .distantFuture, ($0.project ?? "").lowercased(), $0.tty)
                < ($1.state, $1.since ?? .distantFuture, ($1.project ?? "").lowercased(), $1.tty)
        }

        // A HEADER OVER NOTHING IS FURNITURE — printed only when there is at least one row under
        // it to label. It is a `.note` carrying a `SessionRow`, not a new `Kind` case: see the
        // doc on `MenuNode.row` for why that is what keeps SessionMenu.swift's decision count flat.
        if !ordered.isEmpty {
            out.append(MenuNode(.note, "PROJECT · AGENT · STATE · LOAD",
                                row: SessionRow(project: "PROJECT", path: "", state: "AGENT · STATE",
                                                agent: "", figures: "LOAD", note: "", noteToken: "")))
        }

        var lastState: SessionState? = nil
        for s in ordered {
            // A separator marks a STATE BOUNDARY, never the top of the list — the column header
            // immediately above the first row already opens the section, so `lastState == nil`
            // (only true for the very first session) emits none.
            if let lastState, s.state != lastState { out.append(.separator()) }
            lastState = s.state
            out.append(contentsOf: rows(for: s, now: now, loadFor: loadFor,
                                        sessionCommands: sessionCommands, colorFor: colorFor,
                                        detailFor: detailFor, hooksWired: hooksWired))
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

    /// THE TRAFFIC LIGHT, as a token the renderer turns into a colour and a shape.
    ///
    /// The dot used to be the PROJECT's colour — an FNV-1a hash of its path, twelve hues on a
    /// wheel. That was defensible when the menu was a flat list of terminals and the only thing
    /// a colour could do was tell two `sntz_mockups` rows apart. It stopped being defensible the
    /// moment the rows carried state: the founder's own menu showed `37.chute` with a RED dot
    /// while it sat happily in READY FOR A PROMPT, because a hash of the string "37.chute"
    /// happens to land on red. A colour that means nothing, in the position where a colour is
    /// about to mean "stop", is worse than no colour at all.
    ///
    /// Shape carries the meaning and colour is the redundancy, not the other way round — the
    /// renderer draws a filled disc, a ring or a small dot, so the three states are still three
    /// things with the hue removed entirely. Roughly 1 in 12 men cannot separate the red from
    /// the green here, and they are squarely in this product's audience.
    public static func stateToken(_ state: SessionState) -> String {
        switch state {
        case .blocked: return "blocked"
        case .waiting: return "waiting"
        case .working: return "working"
        case .idle:    return "idle"
        case .unknown: return "unknown"
        }
    }

    /// One session: the row itself, then its ⌥ alternates — same identity, same numbers, only
    /// the verb on line 1 changes between them (see `SessionMenu.swift`'s own note on why an
    /// alternate must be exactly as tall as the row it replaces).
    static func rows(for s: Session,
                     now: Date = Date(),
                     loadFor: (String) -> SessionLoad,
                     sessionCommands: (Session) -> [(kind: String, title: String)],
                     colorFor: (String) -> String,
                     detailFor: (Session) -> String,
                     hooksWired: Bool = true) -> [MenuNode] {
        let hex = stateToken(s.state)
        let (figures, note, noteToken) = loadColumns(loadFor(s.tty))

        // NAME AND PATH ARE TWO DIFFERENT CONFIDENCE LEVELS, and the row says so instead of
        // hiding it. `s.project` is ChuteCore's best derivation (git root leaf → cwd leaf →
        // window-title head); `s.cwd` is what the hook itself reported. A name that only came
        // from the title, with no cwd behind it, is exactly the "silently wrong" case this whole
        // redesign exists to end — see docs/specs/… on mockup 2c — so it is not silent here: no
        // cwd means the path cell says so, DIMMED, rather than implying Chute knows where this
        // session lives when all it has is a string another process wrote into a window title.
        let dim = s.cwd == nil
        // "tty ttys004" when nothing at all was derived — still an identifier, never a blank.
        let name = s.project.map { clampedProjectName($0) } ?? "tty \(s.tty)"
        let path = s.cwd.map { PathAbbrev.path($0) } ?? "no project derived"

        // "blocked 22 min" IS THE PRODUCT — the duration is the whole signal a header used to
        // carry. `.idle`/`.unknown` never get a duration: `SessionPhrasing.held` already refuses
        // one for both (a state Chute is not sure of, or not urgent, earns no fake precision), so
        // those two cases are spelled out here instead of asking `held` for an empty string twice.
        let state: String
        switch s.state {
        case .blocked, .waiting, .working:
            state = SessionPhrasing.held(s.state, since: s.since, now: now)
        case .idle:
            state = "no agent running"
        case .unknown:
            state = SessionPhrasing.unknownReason(agent: s.agent, hooksWired: hooksWired)
        }

        let row = SessionRow(project: name, path: path, state: state, agent: detailFor(s),
                             figures: figures, note: note, noteToken: noteToken)
        // The tooltip carries the FULL, UNTRUNCATED name and path — `s.project`/`s.cwd` here, not
        // `name`/`path` above, which are already cut to their column's budget. Whatever col 1 had
        // to cut to fit is still one hover away. `?? name`/`?? path` only matters when there was
        // nothing to cut in the first place — both already hold the same fallback text.
        let toolTip = "\(s.project ?? name) — \(s.cwd ?? path)\n\(s.title) · terminal \(s.tty)"
                    + " · click to bring it forward\n Hold ⌥ for this session's commands."
        var out: [MenuNode] = [
            MenuNode(.session(key: s.key, tty: s.tty, colorHex: hex), flatTitle(row),
                     toolTip: toolTip, row: row, dim: dim)
        ]
        for c in sessionCommands(s) {
            // THE ⌥ FACE: same project, same path, same agent, same load — only line 1's col 2
            // and col 3 change, to the command's own title and its key glyphs. Built from the
            // parent row so the renderer never has to know this rule; it just draws a `SessionRow`.
            let altRow = SessionRow(project: row.project, path: row.path, state: c.title,
                                    agent: row.agent, figures: keyGlyphs(for: c.kind),
                                    note: row.note, noteToken: row.noteToken)
            out.append(MenuNode(.sessionCommand(key: s.key, kind: c.kind, colorHex: hex),
                                flatTitle(altRow), row: altRow, dim: dim))
        }
        return out
    }

    /// The accessibility/title fallback for a row: every non-empty cell, in reading order, joined
    /// the same way a sentence would be. `MenuNode.title` stays populated with this so VoiceOver
    /// and the four existing suite scans (prices, "Refresh", …) that read `.title` keep working.
    static func flatTitle(_ row: SessionRow) -> String {
        [row.project, row.path, row.state, row.agent, row.figures, row.note]
            .filter { !$0.isEmpty }.joined(separator: " · ")
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

    /// Two cells, replacing `suffix`'s one string. `suffix` built "12% CPU · 1.5 GB memory ⚠" as a
    /// single run appended after the row's text — a shape with nowhere for a warning WORD to sit
    /// beside a right-aligned number column. `figures` is col 3's bold, monospaced-digit first
    /// line; `note` is its dim second line — `runaway ⚠` or `peaked 6.1 GB`, never both, because a
    /// live runaway is worth more of a reader's eye right now than what the session once peaked
    /// at. Empty when there is no live process at all — not "0%", which would claim a measurement
    /// that was never taken.
    public static func loadColumns(_ load: SessionLoad)
        -> (figures: String, note: String, noteToken: String) {
        guard load.processes > 0 else { return (figures: "", note: "", noteToken: "") }
        let figures = "\(Int(load.cpuPercent.rounded()))% · \(SystemVitals.bytes(load.residentBytes))"
        if isRunaway(load) { return (figures, "runaway ⚠", "alarm") }
        if let peak = load.peakNote {
            // `peakNote` is always exactly " (peaked X)" — SystemVitals.swift builds it that way —
            // so trimming its two leading and one trailing wrapper characters reuses its ONE
            // "worth showing" condition rather than re-deriving that math a second time here.
            return (figures, String(peak.dropFirst(2).dropLast()), "quiet")
        }
        return (figures, "", "")
    }

    // ── THE NAME COLUMN'S WIDTH CLAMP ───────────────────────────────────────────────────────
    //
    // `PathAbbrev.name`'s budget is in CHARACTERS, exact for col 1's PATH line (10.5pt monospace —
    // every character the same width) but only an APPROXIMATION for col 1's NAME line, set in a
    // PROPORTIONAL 13pt semibold font. Measured 2026-09-08 in
    // docs/specs/MENUBAR-LAYOUT-CALIBRATION.md: a 24-character name built from wide capitals (M,
    // W) renders at 277pt against the 200pt col-2 tab stop. `NSTextTab` does not clip an
    // overflowing run — it pushes the tab that follows out to the NEXT stop, so one bad project
    // name widens the whole menu and drags every column on every row below it out of alignment.
    // Mockup 2c's own caption for this row is "the one that makes a bad project name harmless",
    // so this is the requirement the character budget alone cannot meet by itself.
    public static let nameFont = NSFont.systemFont(ofSize: 13, weight: .semibold)
    /// The col-2 tab stop and the col-3 tab stop, MEASURED — see
    /// docs/specs/MENUBAR-LAYOUT-CALIBRATION.md. Declared once, here, so `SessionMenu.swift`'s
    /// `NSParagraphStyle` and this file's own width clamp read the same two numbers rather than
    /// two copies that can drift apart.
    public static let col2TabStop: CGFloat = 200
    public static let col3TabStop: CGFloat = 500
    /// 10pt of margin below the col-2 tab stop — text landing AT the stop still triggers the same
    /// "tab jumps to the next stop" failure the clamp exists to prevent, so "fits" has to mean
    /// comfortably under it, not exactly at it.
    public static let col1UsableWidth: CGFloat = col2TabStop - 10

    /// `PathAbbrev`'s character budget is the first cut, and for almost every real name it is also
    /// the last one: an ordinary name in ordinary letters is already under the width limit once
    /// truncated to 24 characters, so the common case costs exactly ONE measurement and returns.
    /// Only a pathological name — this file's own suite uses a string of nothing but "W" — needs
    /// the loop below, and it can run at most `defaultNameBudget` times, once per character, so
    /// even the worst case is bounded.
    public static func clampedProjectName(_ raw: String, maxWidth: CGFloat = col1UsableWidth,
                                          font: NSFont = nameFont) -> String {
        func width(_ s: String) -> CGFloat {
            NSAttributedString(string: s, attributes: [.font: font]).size().width
        }
        let budgeted = PathAbbrev.name(raw)
        guard width(budgeted) > maxWidth else { return budgeted }

        // Strip a trailing ellipsis `PathAbbrev.name` may already have added, so the loop shrinks
        // from a fixed point and re-adds exactly ONE ellipsis per pass rather than accumulating.
        var head = budgeted.hasSuffix("…") ? String(budgeted.dropLast()) : budgeted
        while head.count > 1, width(head + "…") > maxWidth {
            head.removeLast()
        }
        return head.isEmpty ? "…" : head + "…"
    }

    // ── THE ⌥ FACE'S GLYPHS ──────────────────────────────────────────────────────────────────
    //
    // "⌥⇧" for col 3's first line when a row wears a command's face — the same modifiers
    // `SessionCommand.modifiers(for:)` already hands `SessionMenu.mask(for:)` to build the real
    // `NSEvent.ModifierFlags`, spelled here as the glyphs a menu actually shows, so `SessionRow`
    // never has to know AppKit's modifier type to describe itself. Every mask carries ⌥ (see that
    // function's own doc comment), so it is the one glyph never conditional on the table below.
    private static let modifierGlyphs: [(SessionCommand.Modifiers, String)] = [
        (.shift, "⇧"), (.command, "⌘"), (.control, "⌃"),
    ]
    public static func keyGlyphs(for kind: String) -> String {
        let wanted = SessionCommand.modifiers(for: kind)
        return "⌥" + modifierGlyphs.filter { wanted.contains($0.0) }.map(\.1).joined()
    }
}
