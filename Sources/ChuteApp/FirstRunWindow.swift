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

    static func markSeen() {
        let dir = (statePath as NSString).deletingLastPathComponent
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        try? #"{"firstRunSeen":true}"#.write(toFile: statePath, atomically: true, encoding: .utf8)
    }

    nonisolated(unsafe) static var window: NSWindow?

    static func show() {
        let w = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 480, height: 380),
                         styleMask: [.titled, .closable], backing: .buffered, defer: false)
        w.title = "Chute"
        w.center()
        w.contentView = makeBody()
        w.isReleasedWhenClosed = false
        window = w
        NSApp.activate(ignoringOtherApps: true)
        w.makeKeyAndOrderFront(nil)
        markSeen()
    }

    static func makeBody() -> NSView {
        let root = NSStackView()
        root.orientation = .vertical
        root.alignment = .leading
        root.spacing = 10
        root.edgeInsets = NSEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)

        let heading = NSTextField(labelWithString: "Chute is almost ready")
        heading.font = .systemFont(ofSize: 18, weight: .semibold)
        root.addArrangedSubview(heading)

        for outcome in Diagnostics.run(Diagnostics.liveEnv()) {
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
        let stack = NSStackView()
        stack.orientation = .horizontal
        stack.spacing = 8
        let mark = NSTextField(labelWithString: o.passed ? "✓" : "⏳")
        mark.textColor = o.passed ? .systemGreen : .systemOrange
        stack.addArrangedSubview(mark)
        let label = NSTextField(labelWithString: o.check.title)
        stack.addArrangedSubview(label)
        if !o.passed {
            // No dead ends: a failing row always carries its reason, visible without a click.
            let why = NSTextField(labelWithString: o.check.why)
            why.font = .systemFont(ofSize: 11)
            why.textColor = .secondaryLabelColor
            why.lineBreakMode = .byTruncatingTail
            why.toolTip = o.check.fix
            stack.addArrangedSubview(why)
        }
        return stack
    }

    final class Handler: NSObject {
        nonisolated(unsafe) static let shared = Handler()

        @objc func fixAll() {
            let binary = Bundle.main.bundlePath + "/Contents/MacOS/chute"
            DispatchQueue.global(qos: .userInitiated).async {
                _ = Shell.run(binary, ["doctor", "--fix"])
                DispatchQueue.main.async {
                    // Re-render from a FRESH environment; never repaint a row green without
                    // re-running the check behind it.
                    FirstRunWindow.window?.contentView = FirstRunWindow.makeBody()
                }
            }
        }

        @objc func skip() {
            FirstRunWindow.markSeen()
            FirstRunWindow.window?.close()
        }
    }
}
