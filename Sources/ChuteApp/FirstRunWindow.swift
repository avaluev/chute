import AppKit
import ChuteCore

/// An LSUIElement app has no Dock icon, so a first launch with no window is indistinguishable
/// from a crash. Shown once, then only on request.
enum FirstRunWindow {
    static var statePath: String {
        (NSHomeDirectory() as NSString).appendingPathComponent(".chute/state.json")
    }

    static func showIfNeeded() {
        guard !FileManager.default.fileExists(atPath: statePath) else { return }
        show()
    }

    @discardableResult
    static func markSeen() -> Bool {
        let dir = (statePath as NSString).deletingLastPathComponent
        do {
            try FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
            try #"{"firstRunSeen":true}"#.write(toFile: statePath, atomically: true, encoding: .utf8)
            return true
        } catch {
            NSLog("Chute: could not record first-run state at \(statePath): \(error.localizedDescription)")
            return false
        }
    }

    nonisolated(unsafe) static var window: NSWindow?

    static func show() {
        let w = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 480, height: 380),
                         styleMask: [.titled, .closable], backing: .buffered, defer: false)
        w.title = "Chute"
        w.center()
        w.contentView = makeBody(outcomes: nil)   // draws immediately: "Checking…"
        w.isReleasedWhenClosed = false
        window = w
        NSApp.activate(ignoringOtherApps: true)
        w.makeKeyAndOrderFront(nil)
        markSeen()
        refresh()
    }

    /// The probe shells out to osascript/pluginkit/ps and blocks. It must never run on the
    /// main thread: this is a menu-bar app with no Dock icon, and a frozen launch reads as a crash.
    static func refresh() {
        DispatchQueue.global(qos: .userInitiated).async {
            let outcomes = Diagnostics.run(Diagnostics.liveEnv())
            DispatchQueue.main.async {
                window?.contentView = makeBody(outcomes: outcomes)
            }
        }
    }

    static func makeBody(outcomes: [CheckOutcome]?) -> NSView {
        let root = NSStackView()
        root.orientation = .vertical
        root.alignment = .leading
        root.spacing = 10
        root.edgeInsets = NSEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)

        let heading = NSTextField(labelWithString: "Chute is almost ready")
        heading.font = .systemFont(ofSize: 18, weight: .semibold)
        root.addArrangedSubview(heading)

        guard let outcomes else {
            root.addArrangedSubview(NSTextField(labelWithString: "Checking your setup…"))
            return root
        }

        for outcome in outcomes {
            root.addArrangedSubview(row(outcome))
        }

        let buttons = NSStackView()
        buttons.orientation = .horizontal
        buttons.spacing = 10
        let fix = NSButton(title: "Fix everything", target: Handler.shared,
                           action: #selector(Handler.fixAll))
        fix.keyEquivalent = "\r"
        let skip = NSButton(title: "Skip", target: Handler.shared, action: #selector(Handler.skip))
        buttons.addArrangedSubview(fix)
        buttons.addArrangedSubview(skip)
        root.addArrangedSubview(buttons)
        return root
    }

    static func row(_ o: CheckOutcome) -> NSView {
        let column = NSStackView()
        column.orientation = .vertical
        column.alignment = .leading
        column.spacing = 2

        let top = NSStackView()
        top.orientation = .horizontal
        top.spacing = 8
        let mark = NSTextField(labelWithString: o.passed ? "✓" : "⏳")
        mark.textColor = o.passed ? .systemGreen : .systemOrange
        top.addArrangedSubview(mark)
        top.addArrangedSubview(NSTextField(labelWithString: o.check.title))
        column.addArrangedSubview(top)

        if !o.passed {
            // Visible, not a tooltip: a user who cannot SEE what to do closes the window.
            let why = NSTextField(labelWithString: o.check.why)
            why.font = .systemFont(ofSize: 11)
            why.textColor = .secondaryLabelColor
            column.addArrangedSubview(why)

            let fix = NSTextField(labelWithString: "→ \(o.check.fix)")
            fix.font = .systemFont(ofSize: 11, weight: .medium)
            fix.textColor = .labelColor
            fix.isSelectable = true      // so a command can be copied
            column.addArrangedSubview(fix)
        }
        return column
    }

    final class Handler: NSObject {
        nonisolated(unsafe) static let shared = Handler()

        @objc func fixAll() {
            let binary = Bundle.main.bundlePath + "/Contents/MacOS/chute"
            DispatchQueue.global(qos: .userInitiated).async {
                _ = Shell.run(binary, ["doctor", "--fix"])
                DispatchQueue.main.async {
                    // Re-verify from a FRESH environment; never repaint a row green without
                    // re-running the check behind it. refresh() is already off-main-safe.
                    FirstRunWindow.refresh()
                }
            }
        }

        @objc func skip() {
            FirstRunWindow.markSeen()
            FirstRunWindow.window?.close()
        }
    }
}
