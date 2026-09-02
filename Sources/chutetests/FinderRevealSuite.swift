import Foundation
import ChuteCore

func finderRevealSuite() {
    T.suite("FinderReveal") {
        // BOTH scripts must carry a deadline. Without one, `osascript` waits on Finder forever —
        // measured past ten minutes with Finder busy — and `chute new --rename` hangs with no
        // output on any user whose Finder happens to be tracking a menu.
        T.ok(FinderReveal.revealScript(path: "/tmp/x").contains("with timeout of"),
             "the reveal is bounded by a timeout")
        T.ok(FinderReveal.beginRenameScript.contains("with timeout of"),
             "and so is the keystroke that starts the rename")
        // AppleScript is a string language: an unescaped quote in a path ends the literal early
        // and the rest of the path becomes code.
        T.eq(AppleScript.escape(#"/tmp/a"b"#), #"/tmp/a\"b"#, "a quote in a path is escaped")
        T.eq(AppleScript.escape(#"/tmp/a\b"#), #"/tmp/a\\b"#, "and so is a backslash")
        T.eq(AppleScript.escape("/tmp/a\nb"), #"/tmp/a\nb"#,
             "a newline — legal in a file name, illegal inside an AppleScript literal — is escaped, not passed")

        let script = FinderReveal.revealScript(path: "/tmp/My File.md")
        T.ok(script.contains("reveal POSIX file \"/tmp/My File.md\""), "the file is revealed by path")
        T.ok(script.contains("activate"), "and Finder is brought forward, or the keystroke goes elsewhere")
        T.ok(FinderReveal.beginRenameScript.contains("key code 36"),
             "Return is what makes Finder start inline rename — there is no API for it")

        // The permission failure must read as an instruction, not as an error code. Measured
        // wording from macOS when Accessibility is not granted.
        let denied = FinderReveal.problem(fromRenameError:
            "36:47: execution error: System Events got an error: osascript is not allowed to send keystrokes. (1002)")
        T.ok(denied.contains("Accessibility"), "a denied keystroke points at the setting that fixes it")
        T.ok(denied.hasPrefix("created"), "and still says the file WAS created")
        T.ok(FinderReveal.problem(fromRenameError: "some AX error (-1719)").contains("Accessibility"),
             "the AX dialect of the same refusal is recognised too")
        T.ok(FinderReveal.problem(fromRenameError: "Finder fell over").contains("Finder fell over"),
             "any other failure is passed through rather than mislabelled as a permission problem")
    }
}
