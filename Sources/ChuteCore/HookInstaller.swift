import Foundation

public struct HookReport: Sendable {
    public let changed: [String]
    public let backupPath: String?
}

public enum HookInstallError: Error, CustomStringConvertible {
    case unreadable(String)
    case unparseable(String)
    case backupFailed(String)
    case validationFailed(String)

    public var description: String {
        switch self {
        case .unreadable(let p):       return "cannot read \(p)"
        case .unparseable(let p):      return "\(p) is not valid JSON — refusing to touch it"
        case .backupFailed(let m):     return "backup failed, nothing was changed: \(m)"
        case .validationFailed(let m): return "refusing to write: \(m)"
        }
    }
}

/// Chute NEVER writes to the user's Claude Code configuration. Decided 2026-08-27:
/// another tool's live settings file is not ours to edit, however carefully — a corrupted
/// agent setup costs the user more than any badge is worth. What remains here is read-only
/// (`status`), generative (`manualSnippet` — JSON the user pastes in themselves), and
/// subtractive (`uninstall` — removes exactly the blocks earlier Chute versions added,
/// backed up first, for machines that still carry them).
public enum HookInstaller {
    public static let marker = "chute-session-state"

    public static let events: [String: SessionState] = [
        "PermissionRequest": .blocked,
        "Stop":              .waiting,
        "UserPromptSubmit":  .working,
        "SessionStart":      .working,
    ]

    /// A single line. Writes one small file and always exits 0 — a Chute failure must never
    /// break the user's agent session. $PPID is the claude process, whose tty is the tab's tty.
    ///
    /// THE SESSION ID comes from `$CLAUDE_CODE_SESSION_ID`, which Claude Code exports into every
    /// hook's environment and which is exactly the uuid its transcript file is named after
    /// (verified 2026-08-28 against ~/.claude/projects/<escaped-cwd>/<uuid>.jsonl). NOT
    /// $CLAUDE_SESSION_ID, which does not exist; and not the JSON on stdin, because reading stdin
    /// from a hook that must never block is a way to hang someone's agent.
    ///
    /// It is filtered to `[a-zA-Z0-9-]` before being embedded. That is a uuid's whole alphabet,
    /// so nothing legitimate is lost — and it means no value of that variable can close the JSON
    /// string and inject a field. `${VAR:-}` keeps it empty rather than unset under `set -u`, so
    /// a different agent, or an older Claude Code, writes "" and every reader treats that as nil.
    /// `ps -o tty=` prints `??` (not empty) when there is no controlling terminal, so we whitelist
    /// alphanumeric tty names rather than just checking for non-empty. The cwd is escaped for JSON
    /// before being embedded, so a directory name containing `"` or `\` cannot break the printf.
    public static func command(for state: SessionState) -> String {
        let name = HookState.stateName(state)
        return "# \(marker)\n"
            + "S=\"$HOME/.chute/sessions\"; mkdir -p \"$S\" 2>/dev/null; "
            + "T=$(ps -o tty= -p $PPID 2>/dev/null | tr -d ' '); "
            + "case \"$T\" in \"\"|*[!a-zA-Z0-9]*) printf '{}\\n'; exit 0;; esac; "
            + "CWD=$(printf '%s' \"$PWD\" | sed 's/\\\\/\\\\\\\\/g; s/\"/\\\\\"/g'); "
            + "SID=$(printf '%s' \"${CLAUDE_CODE_SESSION_ID:-}\" | tr -cd 'a-zA-Z0-9-'); "
            + "printf '{\"tty\":\"%s\",\"state\":\"%s\",\"cwd\":\"%s\",\"session_id\":\"%s\",\"ts\":%s}' "
            + "\"$T\" \"\(name)\" \"$CWD\" \"$SID\" \"$(date +%s)\" > \"$S/$T.json.tmp\" 2>/dev/null "
            + "&& mv \"$S/$T.json.tmp\" \"$S/$T.json\" 2>/dev/null; "
            + "printf '{}\\n'; exit 0"
    }

    /// Our command always OPENS with the marker comment line. Matching the prefix (including its
    /// trailing newline, exactly what `command(for:)` emits) rather than a loose `contains` means
    /// a user command that merely mentions the marker — or one that shares our prefix but diverges,
    /// like `# chute-session-state-mine` — is never mistaken for ours, in either direction.
    public static func isChuteCommand(_ command: String) -> Bool {
        command.hasPrefix("# \(marker)\n")
    }

    /// Is this OUR command, and is it the CURRENT one?
    ///
    /// The snippet gained `$CLAUDE_CODE_SESSION_ID` on 2026-08-28. An earlier one still works —
    /// the badges and the waiting times are unaffected — but it carries no session id, so the
    /// model, the cost and the resume command are all silently missing and nothing on screen
    /// explains why. `hooks status` reports it rather than leaving that to be discovered.
    ///
    /// Matched on the marker the current command actually contains, not on a version number we
    /// would have to remember to bump.
    public static func isCurrent(_ command: String) -> Bool {
        isChuteCommand(command) && command.contains("CLAUDE_CODE_SESSION_ID")
    }

    /// Which of our installed hook commands are out of date, by event name.
    public static func outdatedEvents(settingsPath: String) -> [String] {
        guard let obj = try? loadObject(settingsPath),
              let hooks = obj["hooks"] as? [String: Any] else { return [] }
        return events.keys.filter { event in
            let blocks = (hooks[event] as? [[String: Any]]) ?? []
            return blocks.contains { block in
                ((block["hooks"] as? [[String: Any]]) ?? []).contains { entry in
                    let c = (entry["command"] as? String) ?? ""
                    return isChuteCommand(c) && !isCurrent(c)
                }
            }
        }.sorted()
    }

    static func loadObject(_ path: String) throws -> [String: Any] {
        guard let data = FileManager.default.contents(atPath: path) else {
            throw HookInstallError.unreadable(path)
        }
        guard let obj = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else {
            throw HookInstallError.unparseable(path)
        }
        return obj
    }

    public static func status(settingsPath: String) -> [String: Bool] {
        guard let obj = try? loadObject(settingsPath),
              let hooks = obj["hooks"] as? [String: Any] else {
            return events.keys.reduce(into: [:]) { $0[$1] = false }
        }
        return events.keys.reduce(into: [:]) { out, event in
            let blocks = (hooks[event] as? [[String: Any]]) ?? []
            out[event] = blocks.contains { block in
                ((block["hooks"] as? [[String: Any]]) ?? []).contains {
                    isChuteCommand(($0["command"] as? String) ?? "")
                }
            }
        }
    }

    /// How many hook commands in the user's settings are NOT Chute's — across EVERY event, not
    /// just the four Chute uses.
    ///
    /// `manualSnippet()` returns a complete `"hooks"` object. That is correct for an empty
    /// settings file and a loaded gun for anyone else: paste it over an existing `hooks` key and
    /// every hook another tool installed is gone. Found on a real machine 2026-09-03 — 11
    /// commands across 12 events, none of them Chute's, and the menu row that hands you the
    /// snippet said nothing about merging. This is the number that lets the menu and the CLI warn
    /// with a figure instead of a vague caution, which is the difference between a warning people
    /// read and one they skim.
    ///
    /// Unreadable or absent settings return 0: nothing is there to lose, and a file we cannot
    /// parse is not one to make claims about.
    public static func foreignCommandCount(settingsPath: String) -> Int {
        guard let obj = try? loadObject(settingsPath),
              let hooks = obj["hooks"] as? [String: Any] else { return 0 }
        return hooks.values.reduce(0) { total, blocks in
            total + ((blocks as? [[String: Any]]) ?? []).reduce(0) { n, block in
                n + ((block["hooks"] as? [[String: Any]]) ?? [])
                    .filter { !isChuteCommand(($0["command"] as? String) ?? "") }
                    .count
            }
        }
    }

    /// The user's ENTIRE settings.json, with Chute's four blocks appended into the arrays that
    /// are already there — returned as text, never written anywhere.
    ///
    /// WHY THIS EXISTS. `manualSnippet()` hands over a complete `"hooks"` object and leaves the
    /// hard part to the user: merging it, by hand, into a file that on a real machine is 33 KB
    /// with 11 hooks from another tool in it. Nobody does that correctly at 11pm, and the ones
    /// who try are one careless paste from deleting the other tool's hooks. So Chute does the
    /// merge — the part it can do exactly — and prints the result. The user's own shell does the
    /// write, which is what `applyCommand` below is for.
    ///
    /// The founder's rule of 2026-08-27 is intact and deliberately so: Chute NEVER writes
    /// ~/.claude/settings.json. Computing a value and printing it is not writing. The moment this
    /// function opens that file for writing, it has become the thing that rule forbids.
    ///
    /// APPENDS, never assigns. Every event Chute does not use is passed through untouched, as is
    /// every top-level key. Idempotent: an event that already carries a Chute block is skipped,
    /// so running it twice cannot stack duplicates.
    public static func merged(settingsPath: String) throws -> String {
        var root = try loadObject(settingsPath)
        var hooks = (root["hooks"] as? [String: Any]) ?? [:]
        for (event, state) in events {
            var blocks = (hooks[event] as? [[String: Any]]) ?? []
            let alreadyOurs = blocks.contains { block in
                ((block["hooks"] as? [[String: Any]]) ?? []).contains {
                    isChuteCommand(($0["command"] as? String) ?? "")
                }
            }
            if alreadyOurs { continue }
            blocks.append(["hooks": [["type": "command", "command": command(for: state)]]])
            hooks[event] = blocks
        }
        root["hooks"] = hooks
        let data = try JSONSerialization.data(withJSONObject: root,
                                              options: [.prettyPrinted, .sortedKeys])
        // Prove it parses before anyone is told to write it over their agent's configuration.
        guard (try? JSONSerialization.jsonObject(with: data)) != nil else {
            throw HookInstallError.validationFailed("the merged settings did not parse")
        }
        return String(decoding: data, as: UTF8.self)
    }

    /// The one command a user pastes into a terminal to wire the hooks up.
    ///
    /// NEVER `chute hooks merged > settings.json`. A redirect truncates the target BEFORE the
    /// command on the left runs, so any failure in `merged` — an unparseable file, a missing
    /// binary — leaves the user with an EMPTY agent configuration. It stages through mktemp,
    /// takes a timestamped backup, and `&&` between every step so nothing proceeds past a
    /// failure.
    /// EVERY path is quoted, including the backup's destination — an unquoted one breaks on the
    /// first user whose home directory has a space in it, and it breaks by writing the backup
    /// somewhere else, which is the worst way for a backup to fail.
    ///
    /// `--settings` is always spelled out rather than left to the default. This command rewrites
    /// the file an agent reads; a reader should be able to see which file that is without
    /// knowing what Chute defaults to.
    public static func applyCommand(cli: String, settingsPath: String) -> String {
        let q = "\"\(settingsPath)\""
        let s = "--settings \(q)"
        // THE `{` CHECK IS NOT DECORATION. Every link in this chain is `&&`, which stops on a
        // non-zero exit — and the failure this guards against exits ZERO. `chute` on PATH may be
        // an OLDER copy than the one printing this: 0.2.0 does not know the word `merged` and
        // falls through to `status`, which prints "→ settings: …" and exits 0. The chain would
        // then `mv` that text over the user's settings.json — 33 KB with eleven hooks from other
        // tools in it. Measured on the founder's Mac, 2026-09-04, where PATH had 0.2.0 and the
        // app had 0.2.1. The caller naming its own binary fixes the cause; this fixes the class.
        return "T=$(mktemp) && \(cli) hooks merged \(s) > \"$T\" && "
             + "[ \"$(head -c1 \"$T\")\" = \"{\" ] && "
             + "cp \(q) \"\(settingsPath).bak-$(date +%Y%m%d-%H%M%S)\" && "
             + "mv \"$T\" \(q) && \(cli) hooks status \(s)"
    }

    /// The `hooks` object a user can paste into their own settings.json, verbatim. Chute
    /// generates the JSON but the user's hand does the writing — that is the whole contract.
    public static func manualSnippet() -> String {
        var hooks: [String: Any] = [:]
        for (event, state) in events {
            hooks[event] = [["hooks": [["type": "command", "command": command(for: state)]]]]
        }
        let data = (try? JSONSerialization.data(withJSONObject: ["hooks": hooks],
                                                options: [.prettyPrinted, .sortedKeys])) ?? Data()
        return String(decoding: data, as: UTF8.self)
    }

    @discardableResult
    public static func uninstall(settingsPath: String,
                                 now: Date = Date()) throws -> HookReport {
        let path = URL(fileURLWithPath: settingsPath).resolvingSymlinksInPath().path
        let original = try loadObject(path)
        let originalKeys = Set(original.keys)

        var root = original
        var hooks: [String: Any] = [:]
        if let existing = root["hooks"] {
            guard let obj = existing as? [String: Any] else {
                throw HookInstallError.validationFailed(
                    "`hooks` is not an object — refusing to modify this file")
            }
            hooks = obj
        }
        var changed: [String] = []

        for event in events.keys.sorted() {
            guard let existing = hooks[event] else { continue }
            guard var blocks = existing as? [[String: Any]] else {
                throw HookInstallError.validationFailed(
                    "hooks.\(event) is not an array of objects — refusing to modify this file")
            }
            let before = blocks.count
            blocks.removeAll { block in
                // Only remove a block that is exactly the one we wrote. If someone merged our
                // hook into a block with theirs, leave it alone rather than taking their hook
                // with it.
                guard block["matcher"] == nil,
                      let inner = block["hooks"] as? [[String: Any]],
                      inner.count == 1 else { return false }
                return isChuteCommand((inner[0]["command"] as? String) ?? "")
            }
            if blocks.count != before {
                changed.append(event)
                // Removing our block can empty the event entirely. An empty array is a husk we
                // left behind, not config the user wrote — drop the key so uninstall reverses.
                if blocks.isEmpty { hooks.removeValue(forKey: event) } else { hooks[event] = blocks }
            }
        }
        root["hooks"] = hooks

        // Nothing of ours in the file → nothing to write, no backup to leave behind. This is what
        // lets uninstall.sh run it unconditionally on machines that never had hooks wired.
        guard !changed.isEmpty else { return HookReport(changed: [], backupPath: nil) }

        // Backup only after every shape guard above has passed — a refusal leaves no trace at all.
        let backup = try makeBackup(path, now: now)
        try validateAndWrite(root, originalKeys: originalKeys, path: path)
        return HookReport(changed: changed, backupPath: backup)
    }

    static func makeBackup(_ path: String, now: Date) throws -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyyMMdd-HHmmss"
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "UTC")
        let dest = path + ".chute-backup-" + f.string(from: now)
        do {
            if FileManager.default.fileExists(atPath: dest) {
                try FileManager.default.removeItem(atPath: dest)
            }
            try FileManager.default.copyItem(atPath: path, toPath: dest)
        } catch {
            throw HookInstallError.backupFailed(error.localizedDescription)
        }
        return dest
    }

    /// Nothing is written until the new document is proven to re-parse and to have kept
    /// every top-level key.
    static func validateAndWrite(_ root: [String: Any],
                                 originalKeys: Set<String>,
                                 path: String) throws {
        guard JSONSerialization.isValidJSONObject(root) else {
            throw HookInstallError.validationFailed("result is not a serialisable object")
        }
        // .sortedKeys is deliberate. Swift dictionaries are unordered and hash seeds are
        // randomised per process, so WITHOUT this the same input serialises in a different order
        // every run — reshuffling the user's entire 33 KB file on every install. Sorted normalises
        // once, on first install, then stays byte-identical forever. Preserving the user's original
        // order is not achievable here without text splicing, which guarantee 2 forbids.
        let data = try JSONSerialization.data(withJSONObject: root,
                                              options: [.prettyPrinted, .sortedKeys])
        guard let reparsed = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else {
            throw HookInstallError.validationFailed("result does not re-parse")
        }
        let lost = originalKeys.subtracting(reparsed.keys)
        guard lost.isEmpty else {
            throw HookInstallError.validationFailed("would drop top-level keys: \(lost.sorted())")
        }
        let temp = path + ".chute-tmp"
        try data.write(to: URL(fileURLWithPath: temp))
        _ = try FileManager.default.replaceItemAt(URL(fileURLWithPath: path),
                                                  withItemAt: URL(fileURLWithPath: temp))
    }
}
