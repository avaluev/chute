import Foundation
import ChuteCore

/// ponytail: hand-rolled flag parsing. The grammar itself lives in ChuteCore.ArgParse so the
/// suite can reach it; adopt swift-argument-parser only if flags outgrow this.
struct Args {
    let positional: [String]
    private let flags: [String: String]

    init(_ raw: [String]) {
        (positional, flags) = ArgParse.split(raw)
    }

    func has(_ key: String) -> Bool { flags[key] != nil }

    func value(_ key: String, or fallback: String) -> String {
        guard let v = flags[key], !v.isEmpty else { return fallback }
        return v
    }

    func optional(_ key: String) -> String? {
        guard let v = flags[key], !v.isEmpty else { return nil }
        return v
    }

    /// Positional paths, made absolute. Falls back to the current directory when empty.
    ///
    /// `dropping` skips leading positionals that are not paths — the subcommand word in
    /// `chute basket add <files…>`, for instance.
    ///
    /// `--files-from <file>` adds one path per line. Selecting a few thousand files in Finder
    /// produces a command line that blows past ARG_MAX and the whole action fails with
    /// "argument list too long"; a file has no such limit. A list that was asked for and cannot
    /// be read is an error, never a fallback: it used to become "the current directory", so a
    /// 500-file Copy Full Paths could put one folder on the clipboard under a green HUD.
    func paths(dropping: Int = 0, defaultToCWD: Bool = false) -> [String] {
        var out = Array(positional.dropFirst(dropping))
        if let listFile = optional("files-from") {
            guard let text = try? String(contentsOfFile: listFile, encoding: .utf8) else {
                Out.fail("cannot read --files-from \(listFile)")
            }
            out += ArgParse.pathList(text)
        }
        if out.isEmpty && defaultToCWD {
            return [FileManager.default.currentDirectoryPath]
        }
        return out.map { FileScan.absolute($0) }
    }
}

/// Fixed-width column, truncated to fit. One definition: `ports` and `sessions` each carried
/// their own, and only one of them truncated, so a long project name broke one table and not
/// the other.
func pad(_ s: String, _ n: Int) -> String {
    s.count >= n ? String(s.prefix(n)) : s + String(repeating: " ", count: n - s.count)
}

enum Out {
    static func info(_ s: String) { FileHandle.standardError.write(Data((s + "\n").utf8)) }
    static func line(_ s: String) { print(s) }
    static func fail(_ s: String) -> Never {
        FileHandle.standardError.write(Data(("chute: " + s + "\n").utf8))
        exit(1)
    }
    /// Print to stdout and put on the clipboard unless --no-copy was given.
    ///
    /// NO LONGER FILES ITSELF INTO THE CONTEXT BASKET. It used to — every command that called
    /// this auto-recorded its output, which is what actually filled the owner's basket with
    /// prompts he never asked to keep: only 3 of 10 Finder actions happened to route through
    /// here, so the list looked hardcoded from outside no matter what he did day to day. A basket
    /// entry is a file path now (see `ContextBuffer.swift`), and the only way in is an explicit
    /// `chute basket add <files…>` — this command's own output, which is text, was never a fit
    /// for that store anyway.
    static func deliver(_ text: String, _ args: Args, badge: String? = nil) {
        print(text)
        if !args.has("no-copy") {
            Clipboard.write(text)
            info("→ copied to clipboard" + (badge.map { " · \($0)" } ?? ""))
        } else if let badge {
            info("→ \(badge)")
        }
    }
}
