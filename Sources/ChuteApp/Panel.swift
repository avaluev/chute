import AppKit

/// The window primitives both of Chute's windows need, in one place instead of two.
///
/// `Settings` and `FirstRun` each hand-rolled their own heading/body/padding helpers with the
/// same fonts and the same insets. Two copies of a look is how two windows stop looking alike.
enum UI {
    static func heading(_ s: String) -> NSTextField {
        let t = NSTextField(labelWithString: s)
        t.font = .systemFont(ofSize: 13, weight: .semibold)
        return t
    }

    static func body(_ s: String, width: CGFloat = 460) -> NSTextField {
        let t = NSTextField(wrappingLabelWithString: s)
        t.font = .systemFont(ofSize: 12)
        t.textColor = .secondaryLabelColor
        t.preferredMaxLayoutWidth = width
        return t
    }

    /// A vertical stack pinned to its host with Apple's 20pt window margin. Pinned on all four
    /// edges, not three: anchoring only the top let long text run past the bottom of the window
    /// with no way to reach it, which is what happens at larger accessibility text sizes.
    static func pad(_ stack: NSStackView, inset: CGFloat = 20) -> NSView {
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        let host = NSView()
        host.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: host.leadingAnchor, constant: inset),
            stack.trailingAnchor.constraint(equalTo: host.trailingAnchor, constant: -inset),
            stack.topAnchor.constraint(equalTo: host.topAnchor, constant: inset),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: host.bottomAnchor, constant: -inset),
        ])
        return host
    }
}

/// A window that closes the way every other macOS window closes.
///
/// An LSUIElement app has no menu bar, so ⌘W and Esc reach no Close item — both of Chute's
/// windows could only be dismissed by aiming at the red button. That is not a preference, it is
/// muscle memory older than the app, and honouring it costs the ten lines below.
final class Panel: NSWindow {
    override func cancelOperation(_ sender: Any?) { performClose(nil) }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if event.modifierFlags.contains(.command),
           event.charactersIgnoringModifiers?.lowercased() == "w" {
            performClose(nil)
            return true
        }
        return super.performKeyEquivalent(with: event)
    }

    /// Titled, closable, resizable — resizable because the text inside grows with the reader's
    /// accessibility text size, and a fixed frame clips it with nowhere to scroll.
    static func make(title: String, width: CGFloat, height: CGFloat) -> Panel {
        let w = Panel(contentRect: NSRect(x: 0, y: 0, width: width, height: height),
                      styleMask: [.titled, .closable, .resizable],
                      backing: .buffered, defer: false)
        w.title = title
        w.center()
        w.isReleasedWhenClosed = false
        return w
    }
}
