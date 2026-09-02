import Foundation

/// The CLI's flag grammar, as one pure function the suite can reach — `Args` in the `chute`
/// target is a thin wrapper over it, and that target links no test.
///
/// THE BUG THIS EXISTS FOR. The parser had no notion of a flag that takes no value: any `--flag`
/// swallowed the next word unless that word began with `--`. `chute clean --force ./other` ate
/// `./other` as the value of `--force`, the positional list came out empty, `clean` fell back to
/// the CURRENT directory, and — because `--force` skips the preview — trashed files the user had
/// never named. `chute paths --no-copy a.txt` printed the folder. The Finder templates were safe
/// only because every boolean there happened to be followed by another flag.
///
/// So the set of flags that take a value is written down, once, here. Everything else is a
/// switch, and a switch never consumes what follows it.
public enum ArgParse {
    /// Every flag that takes a value. A flag not in this set is a boolean.
    public static let valueFlags: Set<String> = [
        "format", "sep", "depth", "dir", "ext", "name", "naming", "rules", "agent", "with",
        "kill", "keys", "settings", "files-from", "watch-seconds",
    ]

    public static func split(_ raw: [String], valueFlags: Set<String> = valueFlags)
        -> (positional: [String], flags: [String: String]) {
        var pos: [String] = []
        var fl: [String: String] = [:]
        var i = 0
        while i < raw.count {
            let a = raw[i]
            guard a.hasPrefix("--") else { pos.append(a); i += 1; continue }
            let key = String(a.dropFirst(2))
            if valueFlags.contains(key), i + 1 < raw.count, !raw[i + 1].hasPrefix("--") {
                fl[key] = raw[i + 1]; i += 2
            } else {
                fl[key] = ""; i += 1
            }
        }
        return (pos, fl)
    }

    /// `--files-from`: one path per line, exactly as written. It used to trim whitespace, which
    /// silently renamed any file with a leading or trailing space.
    /// ponytail: a newline inside a file name still splits it; NUL-delimit both sides if that
    /// ever shows up in a real selection.
    public static func pathList(_ text: String) -> [String] {
        text.split(separator: "\n", omittingEmptySubsequences: true).map(String.init)
    }
}
