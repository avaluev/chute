import AppKit
import ChuteCore

enum SessionMenu {
    static func badge(for sessions: [Session]) -> String {
        let n = sessions.filter { $0.state == .blocked || $0.state == .waiting }.count
        return n == 0 ? "⤓" : "⤓ \(n)"
    }

    static func dot(_ hex: String) -> NSImage {
        let size = NSSize(width: 10, height: 10)
        let image = NSImage(size: size)
        image.lockFocus()
        (NSColor(hex: hex) ?? .systemGray).setFill()
        NSBezierPath(ovalIn: NSRect(origin: .zero, size: size)).fill()
        image.unlockFocus()
        return image
    }

    static func elide(_ s: String, _ max: Int = 34) -> String {
        guard s.count > max else { return s }
        let half = (max - 1) / 2
        return String(s.prefix(half)) + "…" + String(s.suffix(half))
    }

    static func age(_ since: Date?) -> String {
        guard let since else { return "" }
        let m = Int(Date().timeIntervalSince(since) / 60)
        if m < 1 { return "just now" }
        return m < 60 ? "\(m)m" : "\(m / 60)h"
    }

    /// Populates the menu AppKit is about to display. Do not build a new NSMenu and assign it to
    /// statusItem.menu from inside menuWillOpen: the object already being tracked is the one passed
    /// in here, so a swap lands on the NEXT open and the user sees the previous state.
    /// Groups by state, assigns ⌥1…⌥8 top-down so the most urgent session is always ⌥1.
    static func populate(_ menu: NSMenu, sessions: [Session], problem: String?,
                         target: AnyObject, action: Selector, openSettings: Selector) {
        menu.removeAllItems()
        var hotkey = 1
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
            ("NEEDS YOU", sessions.filter { $0.state == .blocked || $0.state == .waiting }),
            ("WORKING",   sessions.filter { $0.state == .working }),
            ("SHELLS",    sessions.filter { $0.state == .idle || $0.state == .unknown }),
        ]

        for (title, group) in groups where !group.isEmpty {
            let header = NSMenuItem(title: "\(title)  (\(group.count))", action: nil, keyEquivalent: "")
            header.isEnabled = false
            menu.addItem(header)

            for s in group {
                let detail = s.state == .blocked || s.state == .waiting
                    ? "\(s.state.label) · \(age(s.since))"
                    : elide(s.title)
                // The cost of the session, appended only when it is worth reading: an idle shell
                // showing "0% · 4 MB" is noise in a list you scan to find the busy one.
                let load = SystemVitals.load(forTTY: s.tty, in: samples).label
                let item = NSMenuItem(title: "\(s.project)   \(detail)\(load.isEmpty ? "" : "   \(load)")",
                                      action: action,
                                      keyEquivalent: hotkey <= 8 ? "\(hotkey)" : "")
                item.keyEquivalentModifierMask = [.option]
                item.image = dot(SessionColor.hex(forProject: s.project))
                item.representedObject = s.key
                item.target = target
                item.toolTip = load.isEmpty ? s.title : "\(s.title) — \(load) on \(s.tty)"
                menu.addItem(item)
                hotkey += 1
            }
            menu.addItem(.separator())
        }

        // How the machine itself is doing. The battery sensor is what can be read without root;
        // it is labelled as the battery rather than passed off as a CPU reading.
        var machine = "Mac · thermals \(SystemVitals.thermalPressure(ProcessInfo.processInfo.thermalState))"
        if let c = SystemVitals.temperature() {
            machine = "Mac · battery \(SystemVitals.temperatureLabel(c)) · thermals "
                    + SystemVitals.thermalPressure(ProcessInfo.processInfo.thermalState)
        }
        let vitals = NSMenuItem(title: machine, action: nil, keyEquivalent: "")
        vitals.isEnabled = false
        vitals.toolTip = "Battery sensor — the CPU die sensors need root, which Chute does not ask for."
        menu.addItem(vitals)
        menu.addItem(.separator())

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
