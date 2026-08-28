import AppKit
import ChuteCore

enum SessionMenu {
    /// The menu's numbers, updatable IN PLACE while the menu is open. Rows and the This-Mac
    /// line are refreshed from one shared snapshot, so every number on screen is from the same
    /// instant — a row claiming 171% while the summary shows a different moment is what
    /// "realtime sync" means here.
    struct LiveVitals {
        let rows: [(item: NSMenuItem, tty: String, prefix: String)]
        let machine: NSMenuItem

        func apply(samples: [ProcessSample], batteryCelsius: Double?) {
            for row in rows {
                let load = SystemVitals.load(forTTY: row.tty, in: samples).label
                row.item.title = row.prefix + (load.isEmpty ? "" : "   \(load)")
            }
            machine.title = SystemVitals.machineLine(
                samples: samples,
                cores: ProcessInfo.processInfo.activeProcessorCount,
                thermal: ProcessInfo.processInfo.thermalState,
                batteryCelsius: batteryCelsius)
        }
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
    @discardableResult
    static func populate(_ menu: NSMenu, sessions: [Session], problem: String?,
                         target: AnyObject, action: Selector, openSettings: Selector) -> LiveVitals {
        menu.removeAllItems()
        var liveRows: [(item: NSMenuItem, tty: String, prefix: String)] = []
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
                // The cost of the session, appended only when it is worth reading: an idle shell
                // showing "0% · 4 MB" is noise in a list you scan to find the busy one.
                let load = SystemVitals.load(forTTY: s.tty, in: samples).label
                let prefix = "\(s.project)   \(detail)"
                let item = NSMenuItem(title: "\(prefix)\(load.isEmpty ? "" : "   \(load)")",
                                      action: action,
                                      keyEquivalent: "")
                liveRows.append((item, s.tty, prefix))
                item.image = dot(SessionColor.hex(forProject: s.project))
                item.representedObject = s.key
                item.target = target
                item.toolTip = "\(s.title)\n\(load.isEmpty ? "Using almost no CPU or memory" : load)"
                             + " · terminal \(s.tty) · click to bring it forward"
                menu.addItem(item)
            }
            menu.addItem(.separator())
        }

        // How the machine itself is doing — measurements only, from the SAME snapshot as the
        // rows above, so the numbers reconcile. See `SystemVitals.machineLine`.
        let vitals = NSMenuItem(title: SystemVitals.machineLine(
                                    samples: samples,
                                    cores: ProcessInfo.processInfo.activeProcessorCount,
                                    thermal: ProcessInfo.processInfo.thermalState,
                                    batteryCelsius: SystemVitals.temperature()),
                                action: nil, keyEquivalent: "")
        vitals.isEnabled = false
        vitals.toolTip = "Temperature comes from the battery sensor. The CPU sensors need "
                       + "administrator access, which Chute does not ask for. "
                       + "100% CPU means one full core, as in Activity Monitor. "
                       + "Updates every 2 seconds while the menu is open."
        menu.addItem(vitals)
        menu.addItem(.separator())

        if sessions.isEmpty && problem == nil {
            let empty = NSMenuItem(title: "No terminal sessions", action: nil, keyEquivalent: "")
            empty.isEnabled = false
            menu.addItem(empty)
            menu.addItem(.separator())
        }
        return LiveVitals(rows: liveRows, machine: vitals)
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
