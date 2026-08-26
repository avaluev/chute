import Foundation
import ChuteCore

/// Asks Finder what the user is looking at. Requires Automation permission the first time.
enum FinderBridge {
    static let selectionScript = """
        tell application "Finder"
            set out to ""
            repeat with i in (get selection)
                set out to out & POSIX path of (i as alias) & linefeed
            end repeat
            if out is "" then
                try
                    set out to POSIX path of (target of front window as alias)
                end try
            end if
            return out
        end tell
        """

    /// Selected files, or the front window's folder when nothing is selected.
    static func selection() -> [String] {
        let r = Shell.run("osascript", ["-e", selectionScript])
        return r.out.split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    /// The folder to act inside: the front window, or the parent of the first selected file.
    static func currentFolder() -> String {
        let sel = selection()
        if let first = sel.first {
            return FileScan.isDirectory(first) ? first : (first as NSString).deletingLastPathComponent
        }
        return NSHomeDirectory() + "/Desktop"
    }
}
