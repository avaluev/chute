import Foundation

/// ponytail: hand-rolled flag parsing. ~40 lines beats a dependency for 25 subcommands.
/// Adopt swift-argument-parser only if flags outgrow this.
struct Args {
    let positional: [String]
    private let flags: [String: String]

    init(_ raw: [String]) {
        var pos: [String] = []
        var fl: [String: String] = [:]
        var i = 0
        while i < raw.count {
            let a = raw[i]
            if a.hasPrefix("--") {
                let key = String(a.dropFirst(2))
                if i + 1 < raw.count, !raw[i + 1].hasPrefix("--") {
                    fl[key] = raw[i + 1]; i += 2
                } else {
                    fl[key] = ""; i += 1
                }
            } else {
                pos.append(a); i += 1
            }
        }
        positional = pos
        flags = fl
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
    /// `--files-from <file>` adds one path per line. Selecting a few thousand files in Finder
    /// produces a command line that blows past ARG_MAX and the whole action fails with
    /// "argument list too long"; a file has no such limit.
    func paths(defaultToCWD: Bool = false) -> [String] {
        var out = positional
        if let listFile = optional("files-from"),
           let text = try? String(contentsOfFile: listFile, encoding: .utf8) {
            out += text.split(separator: "\n").map(String.init)
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
        }
        if out.isEmpty && defaultToCWD {
            return [FileManager.default.currentDirectoryPath]
        }
        return out.map { FileScanAbsolute($0) }
    }
}

import ChuteCore
func FileScanAbsolute(_ p: String) -> String { FileScan.absolute(p) }

enum Out {
    static func info(_ s: String) { FileHandle.standardError.write(Data((s + "\n").utf8)) }
    static func line(_ s: String) { print(s) }
    static func fail(_ s: String) -> Never {
        FileHandle.standardError.write(Data(("chute: " + s + "\n").utf8))
        exit(1)
    }
    /// Print to stdout and put on the clipboard unless --no-copy was given.
    /// `record: false` for text that is MADE OUT OF the buffer. `buf all` joins the entries and
    /// hands them back; filing that join adds an eleventh row holding a copy of the other ten,
    /// and `keep` then evicts the oldest of the very things it just concatenated. 0d23f86 fixed
    /// exactly this in the menu bar's bufferFlush and did not look at the CLI, which had the same
    /// bug through the same shared function. A derived blob is not a new thing you collected.
    static func deliver(_ text: String, _ args: Args, badge: String? = nil,
                        label: String? = nil, record: Bool = true) {
        print(text)
        if !args.has("no-copy") {
            Clipboard.write(text)
            // Remembered as it is handed over. Nothing to press afterwards, and nothing watching
            // the pasteboard: this records what WE wrote, at the moment we wrote it.
            if record { ContextBuffer().record(text, label: label ?? badge ?? "") }
            info("→ copied to clipboard" + (badge.map { " · \($0)" } ?? ""))
        } else if let badge {
            info("→ \(badge)")
        }
    }
}
