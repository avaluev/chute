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
/// No amount of tuning `UNUserNotificationCenter` fixes that, because the delay is not ours. So
/// the confirmation a user needs in the first half-second does not go through the notification
/// system at all. This panel appears in the same run loop turn as the result, obeys no
/// notification policy, needs no permission, and cannot be batched into a summary.
///
/// THIS IS THE ONLY SURFACE. It used to be one of two — the panel AND a Notification Centre
/// banner for the same event — which is exactly what a user sees as the same message arriving
/// twice. `notify` now picks one: this panel whenever there is a screen to draw on, a
/// notification only when there is not. Never post both for one action.
enum ResultHUD {
    nonisolated(unsafe) private static var panel: NSPanel?
    nonisolated(unsafe) private static var dismissAt: Date?

    /// How long it stays. Long enough to read six words, short enough that a second action does
    /// not queue behind it. Frequent actions should not be animated or lingered over — the whole
    /// point is that the user has already moved on.
    private static let lifetime: TimeInterval = 1.6

    /// `anchor` is the status item's frame in screen coordinates when it is known, so the HUD
    /// appears under the ⤓ that did the work. Falling back to the top-right of the main screen
    /// keeps it in the same place rather than jumping to wherever the pointer happens to be.
    ///
    /// Returns whether the user was actually shown something. `notify` relies on this to pick
    /// ONE surface: false here — and only false here — is what lets a notification be posted
    /// instead. Never return true on a path that draws nothing, or an action goes unreported.
    @discardableResult
    static func show(_ text: String, anchor: NSRect? = nil) -> Bool {
        // Tests and CI have no window server. Drawing there is a crash, not a feature.
        guard NSApp != nil, !isHeadless else { return false }
        precondition(Thread.isMainThread, "ResultHUD must be shown on the main thread")

        let body = NSTextField(labelWithString: text)
        body.font = .systemFont(ofSize: 13, weight: .medium)
        body.textColor = .labelColor
        body.lineBreakMode = .byTruncatingTail
        body.maximumNumberOfLines = 2
        body.preferredMaxLayoutWidth = 320

        let dot = NSView(frame: NSRect(x: 0, y: 0, width: 8, height: 8))
        dot.wantsLayer = true
        dot.layer?.backgroundColor = NSColor(srgbRed: 0.56, green: 0.86, blue: 0.44, alpha: 1).cgColor
        dot.layer?.cornerRadius = 4
        dot.widthAnchor.constraint(equalToConstant: 8).isActive = true
        dot.heightAnchor.constraint(equalToConstant: 8).isActive = true

        let row = NSStackView(views: [dot, body])
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 10
        row.edgeInsets = NSEdgeInsets(top: 12, left: 16, bottom: 12, right: 18)

        // .hudWindow gives the system's own vibrant panel material, so this looks like macOS
        // rather than like a web overlay someone drew.
        let host = NSVisualEffectView()
        host.material = .hudWindow
        host.blendingMode = .behindWindow
        host.state = .active
        host.wantsLayer = true
        host.layer?.cornerRadius = 10
        host.layer?.masksToBounds = true

        row.translatesAutoresizingMaskIntoConstraints = false
        host.addSubview(row)
        NSLayoutConstraint.activate([
            row.leadingAnchor.constraint(equalTo: host.leadingAnchor),
            row.trailingAnchor.constraint(equalTo: host.trailingAnchor),
            row.topAnchor.constraint(equalTo: host.topAnchor),
            row.bottomAnchor.constraint(equalTo: host.bottomAnchor),
        ])

        let size = row.fittingSize
        let frame = NSRect(origin: .zero, size: NSSize(width: min(size.width, 380), height: size.height))

        // Reuse one panel. A new window per action stacks them and leaks.
        let p = panel ?? makePanel()
        panel = p
        p.contentView = host
        p.setContentSize(frame.size)
        p.setFrameOrigin(origin(for: frame.size, anchor: anchor))
        p.orderFrontRegardless()          // never activates, never steals focus

        // Re-showing extends the deadline rather than restarting a timer per call.
        let deadline = Date().addingTimeInterval(lifetime)
        dismissAt = deadline
        DispatchQueue.main.asyncAfter(deadline: .now() + lifetime + 0.05) {
            guard let due = dismissAt, due <= Date() else { return }   // a newer show won
            panel?.orderOut(nil)
            dismissAt = nil
        }
        return true
    }

    private static var isHeadless: Bool {
        ProcessInfo.processInfo.environment["CHUTE_HEADLESS"] == "1"
    }

    private static func makePanel() -> NSPanel {
        let p = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 320, height: 44),
                        styleMask: [.borderless, .nonactivatingPanel],
                        backing: .buffered, defer: false)
        p.isFloatingPanel = true
        p.level = .statusBar                 // above ordinary windows, below the menu bar itself
        p.backgroundColor = .clear
        p.isOpaque = false
        p.hasShadow = true
        p.ignoresMouseEvents = true          // it is a message, not a control
        p.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        p.hidesOnDeactivate = false
        return p
    }

    /// Under the status item when we know where it is, otherwise the top-right of the screen the
    /// pointer is on — the corner the ⤓ lives in, so the eye goes to the thing that did the work.
    private static func origin(for size: NSSize, anchor: NSRect?) -> NSPoint {
        let screen = NSScreen.screens.first { NSMouseInRect(NSEvent.mouseLocation, $0.frame, false) }
            ?? NSScreen.main
        guard let visible = screen?.visibleFrame else { return .zero }

        if let anchor, anchor.width > 0 {
            let x = min(max(anchor.midX - size.width / 2, visible.minX + 8),
                        visible.maxX - size.width - 8)
            return NSPoint(x: x, y: anchor.minY - size.height - 8)
        }
        return NSPoint(x: visible.maxX - size.width - 12, y: visible.maxY - size.height - 12)
    }
}
