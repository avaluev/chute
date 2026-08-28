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

    static func badge(for sessions: [Session]) -> String {
        let n = sessions.filter { $0.state == .blocked || $0.state == .waiting }.count
        return n == 0 ? "⤓" : "⤓ \(n)"
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

    /// Populates the menu AppKit is about to display. Do not build a new NSMenu and assign it to
    /// statusItem.menu from inside menuWillOpen: the object already being tracked is the one passed
    /// in here, so a swap lands on the NEXT open and the user sees the previous state.
    /// Groups by state, most urgent first.
    ///
    /// NO KEY EQUIVALENTS ON THE SESSION ROWS. They used to carry ⌥1…⌥8, which could never fire:
    /// AppKit matches a key equivalent against the character the keystroke PRODUCES, and ⌥1
    /// produces "¡", not "1". The rows advertised a shortcut that did nothing on every keyboard
    /// layout. A menu that promises a shortcut it does not honour is worse than one that promises
    /// nothing, so the promise is gone. `chute focus <n>` still does this from the terminal.
    static func populate(_ menu: NSMenu, sessions: [Session], problem: String?,
                         target: AnyObject, action: Selector, openSettings: Selector) {
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

        let groups: [(String, [Session])] = [
            ("Waiting for You",  sessions.filter { $0.state == .blocked || $0.state == .waiting }),
            ("Agents Working",   sessions.filter { $0.state == .working }),
            ("Idle Terminals",   sessions.filter { $0.state == .idle || $0.state == .unknown }),
        ]

        for (title, group) in groups where !group.isEmpty {
            let header = NSMenuItem(title: "\(title)  (\(group.count))", action: nil, keyEquivalent: "")
            header.isEnabled = false
            menu.addItem(header)

            for s in group {
                let detail: String
                switch s.state {
                case .blocked, .waiting:
                    detail = SessionPhrasing.waitedFor(s.since)
                case .idle, .unknown:
                    // "37.chute   Terminal" said nothing: every row here is a Terminal. What the
                    // reader wants to know is that nothing is running in it.
                    detail = "no agent running"
                default:
                    detail = SessionPhrasing.elide(s.title)
                }
                // A RUNAWAY IS WORTH SAYING; A NUMBER IS NOT. Every row used to end in
                // "1% CPU · 974 MB memory", which changed every two seconds and answered no
                // question anyone had. What an AI builder actually needs to know is that one of
                // their agents has gone wrong — so nothing is drawn unless it crosses the line.
                let load = SystemVitals.load(forTTY: s.tty, in: samples)
                let warning = SessionMenu.runawayNote(load)
                let item = NSMenuItem(title: "\(s.project)   \(detail)\(warning)",
                                      action: action,
                                      keyEquivalent: "")
                item.image = dot(SessionColor.hex(forProject: s.project))
                item.representedObject = s.key
                item.target = target
                item.toolTip = "\(s.title) · terminal \(s.tty) · click to bring it forward"
                menu.addItem(item)
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
