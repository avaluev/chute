import Foundation

/// Naming and rename-tracking for an image pasted out of the clipboard into a folder.
///
/// The AppKit half (reading the pasteboard, encoding the PNG) lives in the CLI; everything here is
/// pure so the parts that are easy to get subtly wrong — the file name, spotting the rename, and
/// deciding whether the clipboard is still ours to overwrite — are testable without a screen.
public enum PastedImage {
    /// macOS names its own screenshots "Screenshot 2026-08-27 at 14.32.05.png". Matching that
    /// exactly means a pasted image sorts and reads next to real screenshots instead of announcing
    /// that a different tool made it.
    public static func defaultName(at date: Date, locale: Locale = Locale(identifier: "en_US_POSIX")) -> String {
        let f = DateFormatter()
        f.locale = locale
        f.dateFormat = "yyyy-MM-dd 'at' HH.mm.ss"
        return "Screenshot \(f.string(from: date)).png"
    }

    /// The file's identity, which survives a rename. Finding the file again by name is exactly
    /// what does not work here, because the rename is the thing being watched for.
    public static func inode(of path: String) -> UInt64? {
        (try? FileManager.default.attributesOfItem(atPath: path))?[.systemFileNumber] as? UInt64
    }

    /// The current path of the file with this inode, or nil if it left the folder entirely.
    public static func path(ofInode inode: UInt64, in dir: String) -> String? {
        guard let names = try? FileManager.default.contentsOfDirectory(atPath: dir) else { return nil }
        for name in names {
            let candidate = (dir as NSString).appendingPathComponent(name)
            if self.inode(of: candidate) == inode { return candidate }
        }
        return nil
    }

    /// May we replace what is on the clipboard?
    ///
    /// Only if it is still the path we put there. The user renames a file for as long as they feel
    /// like it, and in the meantime they may copy something else entirely — overwriting that would
    /// be the tool stealing the clipboard out from under them.
    public static func mayReplaceClipboard(current: String, weWrote: String) -> Bool {
        current.trimmingCharacters(in: .whitespacesAndNewlines) == weWrote
    }
}
