import Foundation

/// Reveal a just-created file in Finder with its name ready to edit, the way Finder's own
/// "New Folder" behaves.
///
/// There is no API for "begin renaming". Finder starts inline rename when Return is pressed on the
/// selected item, so that is what this sends. Pressing a key on the user's behalf needs
/// Accessibility permission — without it the keystroke silently does nothing, so the failure is
/// reported rather than swallowed.
public enum FinderReveal {
    /// How long Finder gets to answer. AppleScript's own `with timeout of` is the bound, because
    /// `osascript` has no flag for it and `Process` has no deadline — and without one this call
    /// waits FOREVER. Measured 2026-08-28: with Finder busy tracking an open context menu, a
    /// `chute new --rename` sat here past ten minutes with no output. That is not only a stuck
    /// test suite; it is `chute new` hanging on a user whose Finder happens to be busy.
    ///
    /// Five seconds is far longer than a reveal ever takes and far shorter than a person waits
    /// before assuming the command is broken.
    public static let revealTimeoutSeconds = 5

    public static func revealScript(path: String) -> String {
        """
        with timeout of \(revealTimeoutSeconds) seconds
          tell application "Finder"
            reveal POSIX file "\(AppleScript.escape(path))"
            activate
          end tell
        end timeout
        """
    }

    /// key code 36 is Return. Finder turns that into inline rename for the selected item.
    public static let beginRenameScript = """
    with timeout of \(revealTimeoutSeconds) seconds
      tell application "System Events" to key code 36
    end timeout
    """

    /// macOS reports a missing Accessibility permission in more than one dialect: `-1719` from
    /// the AX API, `1002` from System Events, and the plain words in between. Measured: sending
    /// Return from a terminal without the permission gives
    /// "System Events got an error: osascript is not allowed to send keystrokes. (1002)".
    public static func problem(fromRenameError raw: String) -> String {
        let text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let lower = text.lowercased()
        if text.contains("-1719") || text.contains("(1002)")
            || lower.contains("not allowed to send keystrokes") || lower.contains("assistive") {
            return "created — to type the name straight away, allow Chute in "
                 + "System Settings → Privacy & Security → Accessibility"
        }
        return "created, but the rename did not start: \(text)"
    }

    /// Reveals the file and starts renaming it. Returns nil on success, or a sentence explaining
    /// what to do — never throws, because a rename that could not start must not turn a
    /// successfully created file into a failed action.
    /// Set by the smoke suite. `CHUTE_HEADLESS=1` is documented as making the suite runnable
    /// without "a logged-in Mac with Finder", and this call was the one place that still reached
    /// for Finder anyway — so the headless run hung exactly where a CI runner would.
    /// PUBLIC because callers have their own GUI-dependent work to skip, not only this one.
    /// `chute paste-image` polls for 90 seconds waiting for the user to rename the file in
    /// Finder; under CHUTE_HEADLESS that reveal never happens, so the poll waits for something
    /// that cannot occur and the headless run blocks for a minute and a half. The guard was one
    /// line too short.
    public static var isHeadless: Bool { ProcessInfo.processInfo.environment["CHUTE_HEADLESS"] == "1" }

    @discardableResult
    public static func revealAndBeginRename(_ path: String,
                                            settle: TimeInterval = 0.35) -> String? {
        guard !isHeadless else { return nil }
        let reveal = Shell.run("osascript", ["-e", revealScript(path: path)])
        guard reveal.ok else {
            return "created, but Finder did not respond: \(reveal.err.trimmingCharacters(in: .whitespacesAndNewlines))"
        }
        // Finder needs a moment to select the file; Return arriving first renames the wrong thing
        // or nothing at all.
        Thread.sleep(forTimeInterval: settle)

        let rename = Shell.run("osascript", ["-e", beginRenameScript])
        return rename.ok ? nil : problem(fromRenameError: rename.err)
    }
}
