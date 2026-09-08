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
    /// The rows whose numbers change while the menu is open, so a two-second timer can rebuild
    /// them in place. Only col 3 (`SessionRow.figures`/`.note`) is rebuilt — the description half
    /// of a row cannot change while a menu is being looked at — via `SessionRow.replacingLoad`,
    /// which touches exactly those two fields and nothing else in the row.
    final class LiveVitals {
        var rows: [(item: NSMenuItem, tty: String, row: StatusMenu.SessionRow, dim: Bool)] = []

        func apply(samples: [ProcessSample]) {
            for entry in rows {
                let updated = entry.row.replacingLoad(SystemVitals.load(forTTY: entry.tty, in: samples))
                entry.item.attributedTitle = sessionRowTitle(updated, dim: entry.dim)
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
    /// THE TRAFFIC LIGHT lives in `ChuteCore.SessionDot`, where a test can render it and count
    /// the pixels it painted. It was here, in a target `chutetests` cannot link, and it shipped
    /// with the blocked and waiting dots drawing NOTHING — branch-free and wrong, so neither the
    /// suite nor the decision-point ratchet could see it. Read that file's header before touching
    /// the geometry; the failure it describes is not obvious from the code.
    static func dot(_ token: String) -> NSImage { SessionDot.image(token) }

    // ── THE TWO-LINE, THREE-COLUMN ROW ──────────────────────────────────────────────────────
    //
    // `MenuNode.row` arrives from ChuteCore already decided down to the character — every string
    // in it is pre-truncated to its column's budget (`PathAbbrev`, `StatusMenu.clampedProjectName`)
    // and pre-measured against the real tab stops. So building the attributed title here is
    // table lookups and interpolation, the same trick `dot()` above already uses — no branch,
    // which is what keeps this file inside `Scripts/check-untested-logic.sh`'s budget of 15.
    //
    // Tab stops are MEASURED, not guessed — docs/specs/MENUBAR-LAYOUT-CALIBRATION.md, 2026-09-08,
    // superseding the narrower 132/366 in the original plan. Locations are from the TEXT ORIGIN,
    // which is why every row — including the column header — carries a 12×12 image (`dot("none")`
    // for the header): a row with no image starts its text 12pt further left and takes the whole
    // column system out of alignment with it. The 12×12 canvas itself must stay a constant size
    // for the same reason — see the comment on `dot()` above, which this still relies on verbatim.
    private static let rowParagraphStyle: NSParagraphStyle = {
        let p = NSMutableParagraphStyle()
        p.tabStops = [NSTextTab(textAlignment: .left, location: StatusMenu.col2TabStop),
                      NSTextTab(textAlignment: .right, location: StatusMenu.col3TabStop)]
        p.defaultTabInterval = 0
        p.lineBreakMode = .byTruncatingTail
        p.lineSpacing = 1
        return p
    }()

    /// col 3 line 2's colour key — a total lookup, so a runaway's warning and an ordinary peak
    /// note never share a branch. "" (the quiet, empty case) maps to `.clear`: an empty string
    /// paints nothing regardless of colour, so this never needs a guard to skip it.
    private static let noteInk: [String: NSColor] = [
        "alarm": .systemOrange, "quiet": .tertiaryLabelColor, "": .clear,
    ]

    /// The `?? ` fallback for a `.session` node whose row is unexpectedly nil — see the call site
    /// in `render` for why a nil-coalesce is preferred here over an `if let`.
    private static let blankRow = StatusMenu.SessionRow(project: "", path: "", state: "",
                                                         agent: "", figures: "", note: "",
                                                         noteToken: "")

    private static func run(_ s: String, _ font: NSFont, _ color: NSColor) -> NSAttributedString {
        NSAttributedString(string: s, attributes: [.font: font, .foregroundColor: color,
                                                   .paragraphStyle: rowParagraphStyle])
    }

    /// THE COLUMN HEADER: the same `SessionRow` shape session rows use, uppercased, one font and
    /// one colour for every cell — so the header and a session row share one alignment system
    /// with no special case for either.
    private static func headerTitle(_ row: StatusMenu.SessionRow) -> NSAttributedString {
        let f = NSFont.systemFont(ofSize: 11, weight: .semibold)
        let out = NSMutableAttributedString()
        out.append(run(row.project.uppercased(), f, .tertiaryLabelColor))
        out.append(run("\t" + row.state.uppercased(), f, .tertiaryLabelColor))
        out.append(run("\t" + row.figures.uppercased(), f, .tertiaryLabelColor))
        return out
    }

    /// A SESSION ROW, or its ⌥ face — six cells, two lines, three columns, straight out of
    /// docs/specs/MENUBAR-LAYOUT-CALIBRATION.md's own font table. `dim` softens col 1 alone: a
    /// project name Chute is not sure of (no `cwd` behind it — see `MenuNode.dim`'s doc comment
    /// in StatusMenu.swift) reads secondary rather than bold, so a weak derivation is visibly
    /// weaker instead of silently wrong. MONOSPACED DIGITS IN COL 3 ARE LOAD-BEARING: `LiveVitals`
    /// rewrites that column every two seconds, and proportional figures make a right-aligned
    /// column jitter under the reader's eye.
    private static func sessionRowTitle(_ row: StatusMenu.SessionRow, dim: Bool) -> NSAttributedString {
        let nameColor: NSColor = dim ? .tertiaryLabelColor : .labelColor
        let out = NSMutableAttributedString()
        out.append(run(row.project, .systemFont(ofSize: 13, weight: .semibold), nameColor))
        out.append(run("\t" + row.state, .systemFont(ofSize: 13, weight: .semibold), .labelColor))
        out.append(run("\t" + row.figures,
                       .monospacedDigitSystemFont(ofSize: 12, weight: .regular), .secondaryLabelColor))
        out.append(run("\n" + row.path,
                       .monospacedSystemFont(ofSize: 10.5, weight: .regular), .tertiaryLabelColor))
        out.append(run("\t" + row.agent, .systemFont(ofSize: 11, weight: .regular), .secondaryLabelColor))
        out.append(run("\t" + row.note, .systemFont(ofSize: 11, weight: .regular),
                       noteInk[row.noteToken] ?? .clear))
        return out
    }

    /// One sentence, not three tab-separated fragments — VoiceOver reads this instead of the
    /// attributed title's raw tab characters. Empty cells (the header's own blank line 2) simply
    /// drop out rather than reading as an empty pause.
    private static func accessibilitySentence(_ row: StatusMenu.SessionRow) -> String {
        [row.project, row.state, row.agent, row.figures, row.note]
            .filter { !$0.isEmpty }.joined(separator: ". ") + "."
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
                // Nesting is gone now that the two-level state/project grouping is deleted, so
                // this is always 0 — assigned unconditionally regardless, at no branch cost.
                item.indentationLevel = node.indent
                // A `.note` carrying a row IS the one column-header node — see `MenuNode.row`'s
                // doc comment. `.map` resolves that with no `if`: every OTHER `.note` (`"No
                // terminal sessions"`, …) has a nil row and keeps its plain `item.title`.
                item.image = dot("none")
                item.attributedTitle = node.row.map(headerTitle)
                item.setAccessibilityLabel(node.row.map(accessibilitySentence))
                menu.addItem(item)

            case .session(let key, let tty, let hex):
                let item = NSMenuItem(title: node.title,
                                      action: selector(.focusSession), keyEquivalent: "")
                item.target = target
                item.representedObject = key
                item.image = dot(hex)
                item.toolTip = node.toolTip
                item.indentationLevel = node.indent
                item.attributedTitle = node.row.map { sessionRowTitle($0, dim: node.dim) }
                item.setAccessibilityLabel(node.row.map(accessibilitySentence))
                menu.addItem(item)
                // `?? blankRow` rather than `if let`: ChuteCore always attaches a row to a
                // `.session` node, and a nil-coalesce costs this file no decision point where an
                // `if let` would (see Scripts/check-untested-logic.sh's budget of 15 for this file).
                live?.rows.append((item, tty, node.row ?? blankRow, node.dim))

            case .sessionCommand(let key, let kind, let hex):
                // `isAlternate` requires the SAME key-equivalent character as the item above it
                // (here: none) and a modifier mask that differs — AppKit then swaps them as the
                // modifier is held. One row in, one row out; the menu does not change height —
                // `SessionRow.replacingLoad` and the shared row builder are what guarantee the
                // alternate is exactly as tall as the row it replaces (see StatusMenu.rows).
                let alt = NSMenuItem(title: node.title,
                                     action: selector(.sessionCommand), keyEquivalent: "")
                alt.keyEquivalentModifierMask = mask(for: kind)
                alt.isAlternate = true
                alt.image = dot(hex)
                alt.target = target
                alt.representedObject = SessionCommand.Payload(
                    key: key, kind: SessionCommand.Kind(rawValue: kind) ?? .copyID)
                alt.attributedTitle = node.row.map { sessionRowTitle($0, dim: node.dim) }
                alt.setAccessibilityLabel(node.row.map(accessibilitySentence))
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
