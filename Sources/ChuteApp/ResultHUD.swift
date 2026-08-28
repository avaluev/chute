import AppKit
import ChuteCore

/// Instant, on-screen confirmation that a Finder action finished.
///
/// WHY THIS EXISTS. Chute's notification path is fast — measured 2026-08-28 against the unified
/// log, `getNotificationSettings` → `add` → delivered takes **4 milliseconds**. But delivery is
/// not display: macOS decides when a banner appears, and a Focus mode, a Scheduled Summary, or an
/// alert style of "None" can hold it for minutes. The founder reported exactly that — the path was
/// on the clipboard immediately and the banner arrived minutes later.
///
/// THIS IS THE ONLY SURFACE. It used to be one of two — a panel AND a Notification Centre banner
/// for the same event — which is what a user sees as the same message arriving twice. `notify`
/// picks one: this whenever there is somewhere to show it, a notification only when there is not.
///
/// AN NSPOPOVER, NOT A HAND-DRAWN PANEL. This was a borderless `NSPanel` holding an
/// `NSVisualEffectView`, with its own corner radius, its own mask image, its own shadow handling
/// and its own screen-corner arithmetic — and it still showed a bright halo around the corners on
/// a light background, because AppKit derives a window's shadow from the square window alpha no
/// matter what the layer inside is masked to. Three attempts at fixing that were three attempts at
/// re-implementing chrome the system already draws correctly.
///
/// So: none of it. A popover anchored to the status item gets the real material, the real
/// continuous corners, the real shadow and an arrow pointing at the thing that did the work — and
/// it moves with the status item instead of guessing at a screen corner. Roughly half the code of
/// the panel it replaces, and none of the half that was wrong.
enum ResultHUD {
    nonisolated(unsafe) private static var popover: NSPopover?
    nonisolated(unsafe) private static var dismissAt: Date?

    /// How long it stays. Long enough to read six words, short enough that a second action does
    /// not queue behind it. Frequent actions should not be lingered over — the point is that the
    /// user has already moved on.
    private static let lifetime: TimeInterval = 1.8

    /// Returns whether the user was actually shown something. `notify` relies on this to pick ONE
    /// surface: false here — and only false here — is what lets a notification be posted instead.
    /// Never return true on a path that shows nothing, or an action goes unreported.
    @discardableResult
    static func show(_ text: String) -> Bool {
        // Tests and CI have no window server. Drawing there is a crash, not a feature.
        guard NSApp != nil, !isHeadless else { return false }
        precondition(Thread.isMainThread, "ResultHUD must be shown on the main thread")

        // The anchor IS the status item. When the menu bar is full enough that macOS has hidden
        // the item there is nothing to point at and nowhere sensible to put this, so hand the
        // event to the notification instead of drawing it somewhere arbitrary.
        guard let button = (NSApp.delegate as? AppDelegate)?.statusItem?.button,
              button.window != nil, !button.isHidden else { return false }

        let p = popover ?? makePopover()
        popover = p
        p.contentViewController = content(text)
        p.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)

        // A popover is a real accessibility element, unlike the borderless panel this replaces —
        // but it is never focused, so VoiceOver would still say nothing without being told.
        NSAccessibility.post(element: NSApp as Any, notification: .announcementRequested,
                             userInfo: [.announcement: text,
                                        .priority: NSAccessibilityPriorityLevel.high.rawValue])

        // Re-showing extends the deadline rather than starting a second timer per call.
        let deadline = Date().addingTimeInterval(lifetime)
        dismissAt = deadline
        DispatchQueue.main.asyncAfter(deadline: .now() + lifetime + 0.05) {
            guard let due = dismissAt, due <= Date() else { return }   // a newer show won
            popover?.performClose(nil)
            dismissAt = nil
        }
        return true
    }

    private static var isHeadless: Bool {
        ProcessInfo.processInfo.environment["CHUTE_HEADLESS"] == "1"
    }

    private static func makePopover() -> NSPopover {
        let p = NSPopover()
        // .transient so a click anywhere dismisses it, and .semitransient's habit of lingering
        // over other apps is not what a 1.8-second toast wants.
        p.behavior = .transient
        p.animates = true
        return p
    }

    /// The message, and a dot that says whether it went well. `ChuteActions.failurePrefix` is the
    /// contract — pinned in FinderActionsSuite, because a green dot beside the word "Failed" is
    /// worse than no dot at all.
    private static func content(_ text: String) -> NSViewController {
        let failed = text.hasPrefix(ChuteActions.failurePrefix)

        let dot = NSImageView(image: NSImage(
            systemSymbolName: failed ? "xmark.circle.fill" : "checkmark.circle.fill",
            accessibilityDescription: failed ? "failed" : "done") ?? NSImage())
        dot.contentTintColor = failed ? .systemRed : .systemGreen
        dot.setContentHuggingPriority(.required, for: .horizontal)

        let label = NSTextField(wrappingLabelWithString: text)
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.textColor = .labelColor
        label.preferredMaxLayoutWidth = 300
        label.setContentCompressionResistancePriority(.required, for: .vertical)

        let row = NSStackView(views: [dot, label])
        row.orientation = .horizontal
        row.alignment = .firstBaseline
        row.spacing = 8
        row.edgeInsets = NSEdgeInsets(top: 14, left: 16, bottom: 14, right: 18)
        row.translatesAutoresizingMaskIntoConstraints = false

        let host = NSView()
        host.addSubview(row)
        NSLayoutConstraint.activate([
            row.leadingAnchor.constraint(equalTo: host.leadingAnchor),
            row.trailingAnchor.constraint(equalTo: host.trailingAnchor),
            row.topAnchor.constraint(equalTo: host.topAnchor),
            row.bottomAnchor.constraint(equalTo: host.bottomAnchor),
        ])
        host.frame = NSRect(origin: .zero, size: row.fittingSize)

        let vc = NSViewController()
        vc.view = host
        return vc
    }
}
