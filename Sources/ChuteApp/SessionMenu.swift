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

    /// Groups by state, assigns ⌥1…⌥8 top-down so the most urgent session is always ⌥1.
    static func build(sessions: [Session], target: AnyObject, action: Selector) -> NSMenu {
        let menu = NSMenu()
        var hotkey = 1

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
                let item = NSMenuItem(title: "\(s.project)   \(detail)",
                                      action: action,
                                      keyEquivalent: hotkey <= 8 ? "\(hotkey)" : "")
                item.keyEquivalentModifierMask = [.option]
                item.image = dot(SessionColor.hex(forProject: s.project))
                item.representedObject = s.key
                item.target = target
                menu.addItem(item)
                hotkey += 1
            }
            menu.addItem(.separator())
        }

        if sessions.isEmpty {
            let empty = NSMenuItem(title: "No terminal sessions", action: nil, keyEquivalent: "")
            empty.isEnabled = false
            menu.addItem(empty)
            menu.addItem(.separator())
        }
        return menu
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
