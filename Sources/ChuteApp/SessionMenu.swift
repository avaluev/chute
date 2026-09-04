import AppKit
import ChuteCore

/// TURNS `[StatusMenu.MenuNode]` INTO AN `NSMenu`, AND DECIDES NOTHING.
///
/// Every question with a right and a wrong answer — which rows, in what order, whether the trial
/// row appears on day 10, whether Recent Copies is there when empty — is answered by
/// `StatusMenu.model` in ChuteCore, where `chutetests` can link it and ask the same questions.
/// This file knows only how AppKit draws things: images, targets, selectors, modifier masks.
///
/// That split is why this file exists in this shape. Fifty-one menu decisions used to live here,
/// in a target the test suite cannot link, and Recent Copies shipped broken through the gap.
enum SessionMenu {
    /// The rows whose numbers change while the menu is open, so a two-second timer can retitle
    /// them in place. Only the suffix is rebuilt: the description half of a row cannot change
    /// while a menu is being looked at, so the prefix is captured once.
    final class LiveVitals {
        var rows: [(item: NSMenuItem, tty: String, prefix: String)] = []

        func apply(samples: [ProcessSample]) {
            for row in rows {
                row.item.title = row.prefix
                    + StatusMenu.suffix(SystemVitals.load(forTTY: row.tty, in: samples))
            }
        }
    }

    /// Draw the menu bar extra: the mark, and nothing else.
    ///
    /// IT USED TO CARRY A COUNT of the sessions that were blocked or waiting. That number came
    /// from hook records, which report at turn boundaries and never at all for an agent that
    /// ships no hooks — so it could sit at "2 waiting" long after both had been answered, and it
    /// read zero on a machine whose hooks had never been wired, which is the same picture as
    /// "nothing needs you". The founder asked for the status to go; a count of statuses is a
    /// status. What is in the menu bar is Chute's own parachute, and it means Chute is running.
    ///
    /// A template image, not text: a glyph drawn as text takes whatever colour AppKit gives a
    /// status item and does not participate in the menu bar's own tinting, so it came out wrong
    /// against a light bar, a tinted desktop and the reduced-contrast setting. Every one of
    /// Apple's own extras is a template image, which the system recolours for the appearance it
    /// is actually drawing.
    static func applyBadge(to button: NSStatusBarButton?) {
        guard let button else { return }
        button.image = MenuBarMark.image
        button.setAccessibilityLabel("Chute")
        button.imagePosition = .imageOnly
        button.title = ""
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

    /// `NSMenuItem.sectionHeader(title:)` arrived in macOS 14 and is what the system's own menus
    /// use; before that the only way was a disabled item. The deployment target is macOS 13, so

    /// Which modifier reveals which command is `SessionCommand.modifiers`, in ChuteCore, where a
    /// test can assert the four masks are DISTINCT — AppKit draws one alternate per mask, so two
    /// commands that share one means the second row silently never appears. This end only
    /// translates that set into AppKit's.
    private static let flagMap: [(SessionCommand.Modifiers, NSEvent.ModifierFlags)] = [
        (.option, .option), (.shift, .shift), (.command, .command), (.control, .control),
    ]

    static func mask(for kind: String) -> NSEvent.ModifierFlags {
        let wanted = SessionCommand.modifiers(for: kind)
        return flagMap.filter { wanted.contains($0.0) }
                      .reduce(into: NSEvent.ModifierFlags()) { $0.insert($1.1) }
    }

    /// Render the model into the menu AppKit handed us.
    ///
    /// NO KEY EQUIVALENTS ON THE SESSION ROWS. They used to carry ⌥1…⌥8, which could never fire:
    /// AppKit matches a key equivalent against the character the keystroke PRODUCES, and ⌥1
    /// produces "¡", not "1". A menu that promises a shortcut it does not honour is worse than one
    /// that promises nothing. `chute focus <n>` still does this from the terminal.
    @discardableResult
    static func render(_ nodes: [StatusMenu.MenuNode], into menu: NSMenu,
                       target: AnyObject, selector: (StatusMenu.Command) -> Selector?,
                       servers: (NSMenu) -> Void,
                       live: LiveVitals? = nil) -> LiveVitals? {
        for node in nodes {
            switch node.kind {
            case .separator:
                menu.addItem(.separator())

            case .servers:
                servers(menu)

            case .note:
                let item = NSMenuItem(title: node.title, action: nil, keyEquivalent: "")
                item.isEnabled = false
                item.toolTip = node.toolTip
                menu.addItem(item)

            case .session(let key, let tty, let hex, let prefix):
                let item = NSMenuItem(title: node.title,
                                      action: selector(.focusSession), keyEquivalent: "")
                item.target = target
                item.representedObject = key
                item.image = dot(hex)
                item.toolTip = node.toolTip
                menu.addItem(item)
                live?.rows.append((item, tty, prefix))

            case .sessionCommand(let key, let kind, let hex):
                // `isAlternate` requires the SAME key-equivalent character as the item above it
                // (here: none) and a modifier mask that differs — AppKit then swaps them as the
                // modifier is held. One row in, one row out; the menu does not change height.
                let alt = NSMenuItem(title: node.title,
                                     action: selector(.sessionCommand), keyEquivalent: "")
                alt.keyEquivalentModifierMask = mask(for: kind)
                alt.isAlternate = true
                alt.image = dot(hex)
                alt.target = target
                alt.representedObject = SessionCommand.Payload(
                    key: key, kind: SessionCommand.Kind(rawValue: kind) ?? .copyID)
                menu.addItem(alt)

            case .command(let command):
                let item = NSMenuItem(title: node.title, action: selector(command),
                                      keyEquivalent: "")
                // Quit targets NSApp, not us. Everything else is ours.
                item.target = command == .quit ? nil : target
                item.toolTip = node.toolTip
                item.representedObject = node.payload
                menu.addItem(item)

            case .submenu(let children):
                let parent = NSMenuItem(title: node.title, action: nil, keyEquivalent: "")
                let sub = NSMenu()
                render(children, into: sub, target: target, selector: selector,
                       servers: servers, live: live)
                parent.submenu = sub
                menu.addItem(parent)
            }
        }
        return live
    }
}

extension NSColor {
    /// The parse is `SessionColor.rgb`, in ChuteCore. It used to live here, in a target no test
    /// can link — a six-line parser with a sign bug in it and nothing able to ask.
    convenience init?(hex: String) {
        guard let c = SessionColor.rgb(hex: hex) else { return nil }
        self.init(srgbRed: c.red, green: c.green, blue: c.blue, alpha: 1)
    }
}
