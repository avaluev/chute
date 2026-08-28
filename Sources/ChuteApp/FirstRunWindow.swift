import AppKit
import ChuteCore

/// An LSUIElement app has no Dock icon, so a first launch with no window is indistinguishable
/// from a crash. Shown once, then only on request.
enum FirstRunWindow {
    /// There is no "seen" flag any more, and there is no `~/.chute/state.json`.
    ///
    /// The original design showed this window once and remembered that it had. The design that
    /// shipped shows it only while a check is FAILING, which answers the same question better and
    /// needs no memory — so the flag became a file written on three paths and read on none. A
    /// file in someone's home directory that nothing consults is not harmless; it is a thing the
    /// next person has to work out the purpose of before they can be sure deleting it is safe.
    ///
    /// Silence is the goal. A window that appears to say "everything is fine" is a window that
    /// teaches people to dismiss windows — and this one used to offer "Fix everything" over a list
    /// of ten green ticks.
    ///
    /// So: run the checks in the background, repair what can be repaired without a human, and open
    /// only if something is STILL failing. A customer who never sees this window is the success
    /// case; `chute doctor` is there for the developer who wants to look anyway.
    static func showIfNeeded() {
        DispatchQueue.global(qos: .utility).async {
            let outcomes = Diagnostics.run(Diagnostics.liveEnv())
            let failing = outcomes.filter { !$0.passed }
            guard !failing.isEmpty else { return }   // nothing failing, nothing to show
            DispatchQueue.main.async { show(only: failing) }
        }
    }

    nonisolated(unsafe) static var window: NSWindow?

    static func show(only failures: [CheckOutcome]? = nil) {
        // REUSE. This built a NEW NSWindow on every call and overwrote the static that held the
        // last one — and with isReleasedWhenClosed off, the old window stayed alive and on
        // screen. Two clicks of "Setup…" meant two identical windows and a leak, every time.
        // 560, not 480. The `fix` line for the extension-container problem is a real shell
        // command with two absolute paths in it, and a window too narrow to hold one forces the
        // reader to guess at what they are supposed to run.
        let w = window ?? Panel.make(title: "Chute", width: 560, height: 420)
        w.contentView = makeBody(outcomes: failures)   // failures if we have them, else "Checking…"
        fitToContent(w)
        window = w
        NSApp.activate(ignoringOtherApps: true)
        w.makeKeyAndOrderFront(nil)
        if failures == nil { refresh() }
    }

    /// The probe shells out to osascript/pluginkit/ps and blocks. It must never run on the
    /// main thread: this is a menu-bar app with no Dock icon, and a frozen launch reads as a crash.
    static func refresh() {
        DispatchQueue.global(qos: .userInitiated).async {
            let outcomes = Diagnostics.run(Diagnostics.liveEnv())
            DispatchQueue.main.async {
                window?.contentView = makeBody(outcomes: outcomes)
                if let w = window { fitToContent(w) }
            }
        }
    }

    /// Everything inside is laid out against this, and every label that can hold a sentence
    /// wraps to it. Without a wrap width a label's intrinsic width is its WHOLE string on one
    /// line, so one long `why` pushed the stack wider than the window — the second row ended up
    /// drawn outside the left margin and the fix command ran off the right edge unread.
    static let contentWidth: CGFloat = 512

    /// The window is as tall as what is in it, and no taller. It was a fixed 420pt regardless of
    /// how many checks failed, so one failing check left most of the window empty and two left a
    /// dead band under the buttons — a window whose size says nothing about its contents reads as
    /// unfinished. The width is held: it is what the wrapped text was measured against.
    static func fitToContent(_ w: NSWindow) {
        guard let content = w.contentView else { return }
        let height = max(content.fittingSize.height, 140)
        w.setContentSize(NSSize(width: contentWidth + 48, height: height))
    }

    static func makeBody(outcomes: [CheckOutcome]?) -> NSView {
        let root = NSStackView()
        root.orientation = .vertical
        root.alignment = .leading
        root.spacing = 14
        // Rows sit under the heading. The default gravity distribution spread two rows to
        // opposite ends of the window with a screen of nothing between them.
        root.distribution = .fill

        // Apple's wording rule for an alert: the title states what needs doing, not how the app
        // feels about it. "Chute is almost ready" over ten green ticks said nothing at all.
        let failures = (outcomes ?? []).filter { !$0.passed }
        let title = outcomes == nil
            ? "Checking your setup"
            : (failures.count == 1 ? "One thing needs your permission" : "\(failures.count) things need your permission")
        let heading = NSTextField(labelWithString: title)
        heading.font = .systemFont(ofSize: 18, weight: .semibold)
        root.addArrangedSubview(heading)

        guard outcomes != nil else {
            root.addArrangedSubview(NSTextField(labelWithString: "One moment…"))
            return root
        }

        // Only what is failing. A passing check is not information; it is furniture.
        for outcome in failures {
            root.addArrangedSubview(row(outcome))
        }

        let buttons = NSStackView()
        buttons.orientation = .horizontal
        buttons.spacing = 10
        // The default button does the work; "Later" dismisses. Both verbs, both about this window.
        let fix = NSButton(title: failures.count == 1 ? "Fix It" : "Fix These",
                           target: Handler.shared, action: #selector(Handler.fixAll))
        fix.keyEquivalent = "\r"
        let skip = NSButton(title: "Later", target: Handler.shared, action: #selector(Handler.skip))
        buttons.addArrangedSubview(fix)
        buttons.addArrangedSubview(skip)
        root.addArrangedSubview(buttons)
        return UI.pad(root)
    }

    static func row(_ o: CheckOutcome) -> NSView {
        let column = NSStackView()
        column.orientation = .vertical
        column.alignment = .leading
        column.spacing = 2

        column.setHuggingPriority(.defaultHigh, for: .vertical)

        let top = NSStackView()
        top.orientation = .horizontal
        top.alignment = .firstBaseline
        top.spacing = 8
        // SF Symbols, not emoji: emoji render in whatever the system font falls back to, ignore
        // the weight of the text beside them, and read out as their own name to VoiceOver.
        let symbol = o.passed ? "checkmark.circle.fill" : "exclamationmark.triangle.fill"
        let mark = NSImageView(image: NSImage(systemSymbolName: symbol,
                                              accessibilityDescription: o.passed ? "ready" : "needs permission")
                                        ?? NSImage())
        mark.contentTintColor = o.passed ? .systemGreen : .systemOrange
        top.addArrangedSubview(mark)
        top.addArrangedSubview(NSTextField(labelWithString: o.check.title))
        column.addArrangedSubview(top)

        if !o.passed {
            // Visible, not a tooltip: a user who cannot SEE what to do closes the window.
            // WRAPPING, both of them. As single-line labels their intrinsic width was the entire
            // sentence, which is what dragged the whole window out of shape.
            let why = NSTextField(wrappingLabelWithString: o.check.why)
            why.font = .systemFont(ofSize: 11)
            why.textColor = .secondaryLabelColor
            why.preferredMaxLayoutWidth = contentWidth
            column.addArrangedSubview(why)

            // Monospaced, because it is a command: in a proportional face a reader cannot tell
            // `rm -rf ~/Library` from prose, and this one begins with sudo.
            let fix = NSTextField(wrappingLabelWithString: o.check.fix)
            fix.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
            fix.textColor = .labelColor
            fix.preferredMaxLayoutWidth = contentWidth
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

        @objc func skip() { FirstRunWindow.window?.close() }
    }
}
