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
    static func applyBadge(_ token: String = "idle", to button: NSStatusBarButton?) {
        guard let button else { return }
        button.image = MenuBarMark.image(token)
        button.setAccessibilityLabel("Chute")
        button.imagePosition = .imageOnly
        button.title = ""
    }

    /// `lockFocus`/`unlockFocus` is deprecated and draws against whatever context happens to be
    /// current; the block form gets its own and is what AppKit asks for now.
    /// THE TRAFFIC LIGHT, one row at a time.
    ///
    /// Keyed by a STATE token now, not a project hash. Two lookups, both total, so this function
    /// has no branch in it — `Scripts/check-untested-logic.sh` counts every branch in this file
    /// against a baseline of 15 and the whole redesign had a budget of zero.
    ///
    /// SHAPE IS THE SIGNAL AND COLOUR IS THE REDUNDANCY. A filled disc stops you, a ring is
    /// motion, a small dot is nothing to do. Squint or drop the hue and the three are still
    /// three; roughly one man in twelve cannot separate this red from this green, and they are
    /// squarely in this product's audience. `systemRed`/`systemGreen`/`systemOrange` are dynamic
    /// catalog colours, so they re-resolve for light, dark and Increase Contrast on their own.
    private static let ink: [String: NSColor] = [
        "blocked": .systemRed, "waiting": .systemGreen, "working": .systemOrange,
        "idle": .tertiaryLabelColor, "unknown": .tertiaryLabelColor,
    ]
    /// diameter, and how much of the middle to cut out (0 = filled disc, 0.34 = ring).
    private static let form: [String: (d: CGFloat, hole: CGFloat)] = [
        "blocked": (9, 0), "waiting": (9, 0), "working": (9, 0.34),
        "idle": (5, 0), "unknown": (5, 0.34),
    ]

    static func dot(_ token: String) -> NSImage {
        // A CONSTANT CANVAS, whatever the dot's size. AppKit lays a menu item's text out from
        // the right edge of its image, so a 5pt image and a 9pt image put their titles in two
        // different columns and the whole list develops a ragged left margin. The glyph shrinks
        // inside the box; the box never does.
        let box = NSSize(width: 12, height: 12)
        let colour = ink[token] ?? .tertiaryLabelColor
        let f = form[token] ?? (5, 0)
        return NSImage(size: box, flipped: false) { rect in
            let r = NSRect(x: rect.midX - f.d / 2, y: rect.midY - f.d / 2, width: f.d, height: f.d)
            let path = NSBezierPath(ovalIn: r)
            let hole = r.insetBy(dx: f.d * f.hole, dy: f.d * f.hole)
            path.append(NSBezierPath(ovalIn: hole))
            // evenOdd turns the second oval into a hole rather than a second disc. A zero-inset
            // hole is the same rect twice, which cancels to nothing — so "filled" needs no branch.
            path.windingRule = .evenOdd
            colour.setFill()
            path.fill()
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
                // Section headers ("NEEDS YOU 2") sit at 0 and their project sub-headers at 1.
                // Assigned unconditionally: Scripts/check-untested-logic.sh counts every branch
                // in this target against a baseline of 15 for this file, and the two-level menu
                // had a budget of exactly zero new ones.
                item.indentationLevel = node.indent
                menu.addItem(item)

            case .session(let key, let tty, let hex, let prefix):
                let item = NSMenuItem(title: node.title,
                                      action: selector(.focusSession), keyEquivalent: "")
                item.target = target
                item.representedObject = key
                item.image = dot(hex)
                item.toolTip = node.toolTip
                item.indentationLevel = node.indent
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
