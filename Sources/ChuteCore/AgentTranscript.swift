import Foundation

/// What a Claude Code session actually is: which model, at what effort, on which branch, and what
/// it has cost so far.
///
/// ── THE VENDOR BOUNDARY, STATED ONCE ────────────────────────────────────────────────────────
///
/// This file reads another product's private, undocumented format. That is a real coupling and it
/// is accepted deliberately, because the alternative is a menu that says "Claude Code" — which is
/// what Chute displayed until 2026-08-28, and which was not something Chute knew at all: it was
/// the terminal WINDOW TITLE leaking through, a string this app neither derived nor could rely on.
///
/// Four rules keep the coupling honest:
///
///   1. READ ONLY. Chute never writes anything under ~/.claude. Not a cache, not a marker.
///   2. EVERY FIELD OPTIONAL. When the format changes, a row loses a detail. It never throws,
///      never blocks a menu, and never shows a value it is not sure of.
///   3. THE FILE IS FOUND BY NAME, NOT BY A GUESSED PATH. Claude Code stores transcripts under
///      ~/.claude/projects/<escaped-cwd>/<session-uuid>.jsonl, and the escaping is NOT stable —
///      this machine carries both `-Users-…-16-WB-1-Code-Claude` and `-Users-…-16.WB-1.Code-Claude`
///      for the same directory, written by two versions with different rules ('.' and '_' became
///      '-' at some point). Reimplementing that rule means re-deriving it every time it changes.
///      The uuid, by contrast, is the filename exactly. So: scan the project directories for a
///      file with that name. Fifty-odd `fileExists` calls, no rule to maintain, and it cannot
///      silently return the wrong session.
///   4. ONE FIXTURE PINS THE PARSE. `Sources/chutetests/fixtures/transcript.jsonl`. A format
///      change fails a test rather than a customer's menu.
///
/// No reader is written for Codex, Cursor, Gemini or aider. They get their NAME from
/// `TerminalAppAdapter.agentName(in:)` and nothing more, until someone asks for the rest.
public struct AgentTranscript: Sendable, Equatable {
    public let sessionID: String
    public let model: String?
    public let effort: String?
    public let version: String?
    public let branch: String?
    public let cwd: String?
    public let outputTokens: Int
    public let cacheReadTokens: Int
    public let cacheWriteTokens: Int

    public init(sessionID: String, model: String?, effort: String?, version: String?,
                branch: String?, cwd: String?, outputTokens: Int,
                cacheReadTokens: Int, cacheWriteTokens: Int) {
        self.sessionID = sessionID; self.model = model; self.effort = effort
        self.version = version; self.branch = branch; self.cwd = cwd
        self.outputTokens = outputTokens
        self.cacheReadTokens = cacheReadTokens; self.cacheWriteTokens = cacheWriteTokens
    }

    // MARK: - Parsing

    /// Parse JSONL. Later records win for the descriptive fields — a long session changes model,
    /// effort and branch partway through, and the useful answer is what it is doing NOW. Token
    /// counts are the exception: those are cumulative and are summed over everything present.
    ///
    /// A line that will not parse is skipped, never fatal. That is not defensive programming for
    /// its own sake: the last line of a session being written right now is routinely half-flushed,
    /// and a tail read deliberately starts in the middle of one.
    public static func parse(_ text: String) -> AgentTranscript? {
        var id: String?, model: String?, effort: String?, version: String?
        var branch: String?, cwd: String?
        var out = 0, cacheRead = 0, cacheWrite = 0
        var sawAnything = false

        for line in text.split(separator: "\n", omittingEmptySubsequences: true) {
            guard let obj = (try? JSONSerialization.jsonObject(with: Data(line.utf8)))
                    as? [String: Any] else { continue }
            sawAnything = true
            if let v = obj["sessionId"] as? String, !v.isEmpty { id = v }
            if let v = obj["version"] as? String, !v.isEmpty { version = v }
            if let v = obj["gitBranch"] as? String, !v.isEmpty { branch = v }
            if let v = obj["cwd"] as? String, !v.isEmpty { cwd = v }
            if let v = obj["effort"] as? String, !v.isEmpty { effort = v }

            guard let message = obj["message"] as? [String: Any] else { continue }
            if let m = message["model"] as? String, !m.isEmpty { model = m }
            if let usage = message["usage"] as? [String: Any] {
                out        += (usage["output_tokens"] as? Int) ?? 0
                cacheRead  += (usage["cache_read_input_tokens"] as? Int) ?? 0
                cacheWrite += (usage["cache_creation_input_tokens"] as? Int) ?? 0
            }
        }

        guard sawAnything, let id else { return nil }
        return AgentTranscript(sessionID: id, model: model, effort: effort, version: version,
                               branch: branch, cwd: cwd, outputTokens: out,
                               cacheReadTokens: cacheRead, cacheWriteTokens: cacheWrite)
    }

    // MARK: - Reading

    /// Read a transcript. The WHOLE file, deliberately.
    ///
    /// The first version read only the last 64 KB, on the theory that these run to megabytes and
    /// the menu has a 300 ms budget. It was measured instead of assumed: the largest transcript on
    /// this machine is 12.4 MB and 3,584 records, and a full parse of it takes 37 ms — in Python.
    /// So the tail read bought nothing worth having, and it cost something real: token totals are
    /// CUMULATIVE, so a windowed read reports the cost of the last few turns while looking exactly
    /// like the cost of the session. It said "17k out" for a session that had produced 353k. A
    /// number that is wrong in a way the reader cannot detect is worse than no number.
    ///
    /// It is still never called on the main thread, and the caller caches on (mtime, size) — 37 ms
    /// per session across eleven sessions is fine in the background and is not fine in a menu.
    ///
    /// A line that will not parse is skipped rather than fatal: the last line of a session being
    /// written right now is routinely half-flushed.
    public static func readFile(_ path: String) -> AgentTranscript? {
        guard let text = try? String(contentsOfFile: path, encoding: .utf8) else { return nil }
        return parse(text)
    }

    /// Locate a session's transcript by its uuid — see rule 3 above.
    public static func find(sessionID: String,
                            projectsDir: String = NSHomeDirectory() + "/.claude/projects") -> String? {
        // A uuid is the whole of the filename. Refuse anything that is not one rather than let a
        // value from a hook file compose a path.
        guard !sessionID.isEmpty,
              sessionID.allSatisfy({ $0.isHexDigit || $0 == "-" }) else { return nil }
        let fm = FileManager.default
        guard let dirs = try? fm.contentsOfDirectory(atPath: projectsDir) else { return nil }
        for dir in dirs {
            let candidate = "\(projectsDir)/\(dir)/\(sessionID).jsonl"
            if fm.fileExists(atPath: candidate) { return candidate }
        }
        return nil
    }

    public static func read(sessionID: String) -> AgentTranscript? {
        find(sessionID: sessionID).flatMap { readFile($0) }
    }

    // MARK: - Display

    /// How people say these models out loud. An id that is not in the table is shown EXACTLY as
    /// it arrived: inventing a friendly name for a model nobody here has heard of is how a menu
    /// starts describing something other than what is running.
    static let modelNames: [(prefix: String, name: String)] = [
        ("claude-opus-5",     "Opus 5"),
        ("claude-opus-4-7",   "Opus 4.7"),
        ("claude-opus-4-6",   "Opus 4.6"),
        ("claude-opus-4-1",   "Opus 4.1"),
        ("claude-opus-4",     "Opus 4"),
        ("claude-sonnet-5",   "Sonnet 5"),
        ("claude-sonnet-4-5", "Sonnet 4.5"),
        ("claude-sonnet-4",   "Sonnet 4"),
        ("claude-haiku-4-5",  "Haiku 4.5"),
        ("claude-haiku-4",    "Haiku 4"),
        ("claude-fable-5",    "Fable 5"),
    ]

    public static func displayModel(_ id: String?) -> String? {
        guard let id else { return nil }
        // Longest prefix first, so "claude-opus-4-1" cannot be swallowed by "claude-opus-4".
        return modelNames.sorted { $0.prefix.count > $1.prefix.count }
            .first { id.hasPrefix($0.prefix) }?.name ?? id
    }

    /// Tokens, never dollars.
    ///
    /// A price is a number on somebody else's pricing page and it is wrong the week they change
    /// it — this repo already refuses to write those down. Tokens are a fact about what happened.
    /// If a currency figure is ever wanted it reads a rate table with a `retrievedOn` date and
    /// says which date it is quoting.
    public static func costLabel(output: Int, cacheRead: Int) -> String? {
        guard output > 0 || cacheRead > 0 else { return nil }
        return "\(compact(output)) out · \(compact(cacheRead)) cached"
    }

    static func compact(_ n: Int) -> String {
        switch n {
        case 1_000_000...:  return String(format: "%.1fM", Double(n) / 1_000_000)
        case 1_000...:      return "\(Int((Double(n) / 1_000).rounded()))k"
        default:            return "\(n)"
        }
    }
}

/// A read-through cache, because the menu must never wait on a file.
///
/// `AgentTranscript.readFile` takes about 37 ms on the largest transcript here. That is fine on a
/// background queue and it is not fine inside `menuWillOpen`, which runs while the user is looking
/// at a menu that has not drawn yet — with eleven sessions it would be most of a second of nothing.
///
/// So the menu only ever asks for what is already known (`cached`, which never touches the disk),
/// and refreshing happens on the event that means a session changed: the DispatchSource watching
/// ~/.chute/sessions. By the time anyone opens the menu the answer is usually already here, and
/// when it is not, the row simply renders without a model and has one on the next open. A row that
/// is one open late is fine; a menu that stalls is a bug.
///
/// Entries are invalidated on (mtime, size) rather than on a timer: a transcript that has not been
/// written to cannot have changed, and re-parsing 12 MB to learn that is work for nothing.
public final class TranscriptStore: @unchecked Sendable {
    private struct Entry { let stamp: Date; let size: UInt64; let transcript: AgentTranscript? }
    private var entries: [String: Entry] = [:]
    private let lock = NSLock()

    public init() {}

    /// Cache only. Never reads the disk, never blocks, safe from the main thread.
    public func cached(_ sessionID: String?) -> AgentTranscript? {
        guard let sessionID else { return nil }
        lock.lock(); defer { lock.unlock() }
        return entries[sessionID]?.transcript
    }

    /// Re-read anything whose file has changed. Call from a background queue.
    public func refresh(sessionIDs: [String]) {
        for id in sessionIDs {
            guard let path = AgentTranscript.find(sessionID: id) else { continue }
            let attrs = try? FileManager.default.attributesOfItem(atPath: path)
            let stamp = (attrs?[.modificationDate] as? Date) ?? .distantPast
            let size  = (attrs?[.size] as? NSNumber)?.uint64Value ?? 0

            lock.lock()
            let known = entries[id]
            lock.unlock()
            if let known, known.stamp == stamp, known.size == size { continue }

            let parsed = AgentTranscript.readFile(path)
            lock.lock()
            entries[id] = Entry(stamp: stamp, size: size, transcript: parsed)
            lock.unlock()
        }
    }
}
