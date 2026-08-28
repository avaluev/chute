import AppKit
import ChuteCore

enum SessionMenu {
    // NO LIVE VITALS, AND NO TIMER. A `LiveVitals` struct used to hold every row so a
    // two-second timer could retitle them with fresh CPU and memory figures while the menu was
    // open. Every number it refreshed has been deleted, so the machinery that refreshed them
    // went with it: the menu is already rebuilt from scratch on every open, which is the only
    // moment anyone is looking at it.

    /// THE ONLY MACHINE FACT WORTH A MENU ROW: this agent has gone wrong.
    ///
    /// Both thresholds live here and nowhere else. `cpuPercent` is percent of ONE core, the way
    /// `ps` and Activity Monitor report it, so 300 means three cores pinned — a coding agent
    /// doing that for as long as it takes you to open a menu is stuck in a loop, not thinking.
    /// The memory figure catches the other failure: an agent that has been running for hours and
    /// is now the reason everything else is swapping.
    ///
    /// Deliberately silent below these. A row that always carries a number is a row nobody reads,
    /// which is exactly how the old "1% CPU · 974 MB memory" suffix earned its deletion.
    static let runawayCPUPercent = 250.0
    static let runawayBytes: UInt64 = 8 * 1_073_741_824   // 8 GB

    static func runawayNote(_ load: SessionLoad) -> String {
        if load.cpuPercent >= runawayCPUPercent {
            return "   ⚠ \(Int(load.cpuPercent.rounded()))% CPU"
        }
        if load.residentBytes >= runawayBytes {
            return "   ⚠ \(SystemVitals.bytes(load.residentBytes))"
        }
        return ""
    }

    static func attentionCount(_ sessions: [Session]) -> Int {
        sessions.filter { $0.state == .blocked || $0.state == .waiting }.count
    }

    /// Draw the menu bar extra: a TEMPLATE IMAGE, plus a count when something wants you.
    ///
    /// It used to draw the literal text "⤓ 3". A glyph rendered as text is drawn in the text
    /// colour AppKit happens to give a status item and does not participate in the menu bar's own
    /// tinting — so it came out wrong against a light menu bar, against a tinted desktop, and in
    /// the reduced-contrast settings. Every one of Apple's own extras is a template image, which
    /// the system recolours for the appearance it is actually drawing.
    ///
    /// The count stays as text beside it, which is what the system's own Wi-Fi and battery items
    /// do when they have a number to show. Zero shows no number at all rather than "0": nothing
    /// is waiting, and a badge that reads zero is a badge you learn to ignore.
    static func applyBadge(to button: NSStatusBarButton?, count: Int) {
        guard let button else { return }
        let symbol = NSImage(systemSymbolName: "arrow.down.to.line",
                             accessibilityDescription: count == 0
                                ? "Chute" : "Chute — \(count) waiting for you")
        symbol?.isTemplate = true
        button.image = symbol
        button.imagePosition = count == 0 ? .imageOnly : .imageLeading
        button.title = count == 0 ? "" : " \(count)"
    }

    /// `lockFocus`/`unlockFocus` is deprecated and draws against whatever context happens to be
    /// current; the block form gets its own and is what AppKit asks for now.
    static func dot(_ hex: String) -> NSImage {
        let size = NSSize(width: 10, height: 10)
        return NSImage(size: size, flipped: false) { rect in
            (NSColor(hex: hex) ?? .systemGray).setFill()
            NSBezierPath(ovalIn: rect).fill()
            return true
        }
    }

    /// A section header, the way macOS draws one.
    ///
    /// `NSMenuItem.sectionHeader(title:)` arrived in macOS 14 and is what the system's own menus
    /// use; before that the only way was a disabled item, which is what this app shipped. The
    /// deployment target is macOS 13 (Package.swift), so both exist and the newer one is used
    /// wherever it can be.
    static func header(_ title: String, count: Int) -> NSMenuItem {
        let text = "\(title)  (\(count))"
        if #available(macOS 14, *) { return NSMenuItem.sectionHeader(title: text) }
        let item = NSMenuItem(title: text, action: nil, keyEquivalent: "")
        item.isEnabled = false
        return item
    }

    /// Populates the menu AppKit is about to display. Groups by state, most urgent first.
    ///
    /// NO KEY EQUIVALENTS ON THE SESSION ROWS. They used to carry ⌥1…⌥8, which could never fire:
    /// AppKit matches a key equivalent against the character the keystroke PRODUCES, and ⌥1
    /// produces "¡", not "1". A menu that promises a shortcut it does not honour is worse than one
    /// that promises nothing. `chute focus <n>` still does this from the terminal.
    ///
    /// PER-SESSION COMMANDS ARE ⌥ ALTERNATES, and that is a considered trade. An NSMenuItem that
    /// owns a submenu does not fire its own action — AppKit will not do both — and the hero job
    /// here is *click the row, that terminal comes forward*. Making that cost an extra motion to
    /// buy a chevron would be a bad exchange. Alternates are the pattern the system menus use for
    /// exactly this, and every one of these commands is also in the free CLI, which is where
    /// discoverability actually lives.
    static func populate(_ menu: NSMenu, sessions: [Session], problem: String?,
                         transcripts: TranscriptStore,
                         target: AnyObject, action: Selector, openSettings: Selector,
                         alternate: Selector) {
        // NOT cleared here — AppDelegate.populateBody does it, on every branch. See the note there.

        // One `ps` for the whole menu. Sampling per row would be thirteen process listings for a
        // menu the user is already waiting on.
        let samples = SystemVitals.sample()

        if let problem {
            let item = NSMenuItem(title: "Cannot read Terminal — click to fix",
                                  action: openSettings, keyEquivalent: "")
            item.target = target
            item.toolTip = problem
            menu.addItem(item)
            menu.addItem(.separator())
        }

        let waiting = sessions.filter { $0.state == .blocked || $0.state == .waiting }
        let working = sessions.filter { $0.state == .working }
        let idle    = sessions.filter { $0.state == .idle || $0.state == .unknown }

        for (title, group) in [("Waiting for You", waiting), ("Working", working)] where !group.isEmpty {
            menu.addItem(header(title, count: group.count))
            for s in group { addRow(s, to: menu, samples: samples, transcripts: transcripts,
                                    target: target, action: action, alternate: alternate) }
            menu.addItem(.separator())
        }

        // IDLE COLLAPSES PAST THREE. These are the sessions you never act on, and on a machine
        // with eleven terminals open they push the group you DID open the menu for off the top.
        if !idle.isEmpty {
            menu.addItem(header("Idle", count: idle.count))
            if idle.count <= collapseIdleAbove {
                for s in idle { addRow(s, to: menu, samples: samples, transcripts: transcripts,
                                       target: target, action: action, alternate: alternate) }
            } else {
                let holder = NSMenuItem(title: "\(idle.count) idle terminals", action: nil, keyEquivalent: "")
                let sub = NSMenu()
                for s in idle { addRow(s, to: sub, samples: samples, transcripts: transcripts,
                                       target: target, action: action, alternate: alternate) }
                holder.submenu = sub
                menu.addItem(holder)
            }
            menu.addItem(.separator())
        }

        if sessions.isEmpty && problem == nil {
            let empty = NSMenuItem(title: "No terminal sessions", action: nil, keyEquivalent: "")
            empty.isEnabled = false
            menu.addItem(empty)
            menu.addItem(.separator())
        }
    }

    static let collapseIdleAbove = 3

    static func addRow(_ s: Session, to menu: NSMenu, samples: [ProcessSample],
                       transcripts: TranscriptStore, target: AnyObject,
                       action: Selector, alternate: Selector) {
        let transcript = transcripts.cached(s.sessionID)
        let detail = SessionPhrasing.detail(agent: s.agent, transcript: transcript)
        let elapsed: String = {
            switch s.state {
            case .blocked, .waiting: return "   " + SessionPhrasing.waitedFor(s.since)
            default: return ""
            }
        }()
        let warning = runawayNote(SystemVitals.load(forTTY: s.tty, in: samples))

        let item = NSMenuItem(title: "\(s.project)   \(detail)\(elapsed)\(warning)",
                              action: action, keyEquivalent: "")
        item.image = dot(SessionColor.hex(forProject: s.project))
        item.representedObject = s.key
        item.target = target
        item.toolTip = "\(s.title) · terminal \(s.tty) · click to bring it forward"
                     + "\n Hold ⌥ for this session's commands."
        menu.addItem(item)

        // The ⌥ face of the same row. `isAlternate` requires the SAME key-equivalent character as
        // the item above it (here: none) and a modifier mask that differs — AppKit then swaps them
        // as the modifier is held. One row in, one row out; the menu does not change height.
        for command in SessionCommand.available(for: s, transcript: transcript) {
            let alt = NSMenuItem(title: "\(s.project)   \(command.title)",
                                 action: alternate, keyEquivalent: "")
            alt.keyEquivalentModifierMask = command.mask
            alt.isAlternate = true
            alt.image = dot(SessionColor.hex(forProject: s.project))
            alt.representedObject = SessionCommand.Payload(key: s.key, kind: command.kind)
            alt.target = target
            menu.addItem(alt)
        }
    }
}

/// The commands a single session offers, and the modifier that reveals each one.
///
/// Four commands on one row means four alternates, and AppKit shows one alternate per distinct
/// modifier mask. So they are spread across ⌥, ⌥⇧, ⌥⌘ and ⌥⌃ rather than crammed into a submenu
/// that would cost the row its single-click focus. The tooltip on the primary row says ⌥ exists;
/// `chute resume`, `chute sessions --json` and the Settings hint carry the rest.
enum SessionCommand {
    enum Kind: String { case copyID, copyResume, tmux, copyCost }

    struct Payload { let key: String; let kind: Kind }

    struct Offer { let kind: Kind; let title: String; let mask: NSEvent.ModifierFlags }

    /// Only what this session can actually do. A command that cannot work is not shown greyed
    /// out — it is not shown, because a disabled row still costs the reader a glance to dismiss.
    static func available(for s: Session, transcript: AgentTranscript?) -> [Offer] {
        guard let sessionID = s.sessionID else { return [] }   // an older hook: nothing to resume
        var offers = [Offer(kind: .copyID, title: "Copy Session ID", mask: [.option])]

        // Only where the agent's resume syntax is actually known. Offering "Copy Resume Command"
        // for an agent we would have to guess at puts a failing command on someone's clipboard.
        let canResume = ResumeCommand.resume(agent: s.agent, sessionID: sessionID) != nil
        if canResume {
            offers.append(Offer(kind: .copyResume, title: "Copy Resume Command", mask: [.option, .shift]))
            if hasTmux {
                offers.append(Offer(kind: .tmux, title: "Continue in tmux", mask: [.option, .command]))
            }
        }
        if let t = transcript,
           AgentTranscript.costLabel(output: t.outputTokens, cacheRead: t.cacheReadTokens) != nil {
            offers.append(Offer(kind: .copyCost, title: "Copy Cost So Far", mask: [.option, .control]))
        }
        return offers
    }

    /// Checked once. `tmux` is a Homebrew install on most machines and its absence is permanent
    /// for the length of a session; offering a command that cannot run is worse than not offering it.
    static let hasTmux = Shell.which("tmux") != nil
}

extension NSColor {
    convenience init?(hex: String) {
        var s = hex
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6, let v = UInt32(s, radix: 16) else { return nil }
        self.init(srgbRed: CGFloat((v >> 16) & 0xFF) / 255,
                  green:   CGFloat((v >> 8) & 0xFF) / 255,
                  blue:    CGFloat(v & 0xFF) / 255,
                  alpha: 1)
    }
}
