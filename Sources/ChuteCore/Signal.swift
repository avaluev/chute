import Foundation

/// `SessionState` gets `Equatable` for free — synthesized alongside `Comparable` in Session.swift,
/// same file as the declaration, which is the one place Swift allows the auto-derivation to fire.
/// Nothing there ever needed to put a `SessionState` in a `Dictionary`, so `Hashable` was never
/// asked for. `Signal.counts` below is the first caller that does, and cross-file synthesis isn't
/// a thing Swift offers — but the raw `Int` is already a stable, unique fingerprint per case, so
/// hand-writing `hash(into:)` is one line, not a reason to go edit a file another agent owns.
extension SessionState: Hashable {
    public func hash(into hasher: inout Hasher) { hasher.combine(rawValue) }
}

/// ONE NUMBER FOR THE WHOLE MACHINE — the answer to "do I need to look at a terminal right now",
/// collapsed from every live session down to the single worst one. Where `Session`/`StatusMenu`
/// answer "what is every tab doing" as a list for a menu you open and read, `Signal` answers the
/// glance a menu-bar badge or a shell prompt needs, and it inherits the rule the rest of the hook
/// system already lives by (see StateResolver.swift): a state is never invented from a proxy —
/// Terminal's `busy` flag, a stale title glyph. It comes from a hook, live and fresh, or it does
/// not count.
public struct Signal: Sendable, Equatable {
    /// Worst LIVE + FRESH state across every session Chute can currently see (`SessionState` is
    /// `Comparable` precisely so `.min()` reads as "worst" — see SignalReader.read). `.unknown`
    /// when nothing survives: either no hooks exist at all, or every hook that exists is dead
    /// (closed tab) or stale. `hooksInstalled` below is what tells those two apart.
    public let state: SessionState
    /// When the WINNING session entered `state` — not "now", not "last read". A badge that names
    /// a state with no duration next to it is the badge StatusMenu.swift deleted and brought
    /// back for ("blocked 22 min" IS the product, not "blocked"); see SessionPhrasing.held.
    public let since: Date?
    public let tty: String?
    /// Derived from the hook's `cwd` via `SignalReader.project(cwd:)` — never a window title.
    /// The title is user-editable and Claude Code never clears its own glyph out of it once a
    /// turn ends, so it survives as an artifact, not as evidence (see the note atop
    /// StateResolver.swift for the incident that ruled it out as a source of truth).
    public let project: String?
    public let sessionID: String?
    /// Every surviving state, tallied, so a caller can say "3 waiting" without re-running the
    /// filter `read` already applied.
    public let counts: [SessionState: Int]
    /// False means Chute cannot see this machine at all — the hook directory has never had a
    /// file written into it. That must never render the same as `state == .idle` or an empty
    /// `counts`: both of those also happen on an INSTRUMENTED machine with nothing going on right
    /// now, and treating the two as one is the exact bug that got the old menu-bar badge deleted
    /// (commit 2849347) — reading zero on a machine with no hooks installed looked pixel-identical
    /// to "nothing needs you" on a machine Chute was actually watching. Chute BLIND must say so,
    /// not read as Chute CALM.
    public let hooksInstalled: Bool

    public init(state: SessionState, since: Date?, tty: String?, project: String?,
               sessionID: String?, counts: [SessionState: Int], hooksInstalled: Bool) {
        self.state = state; self.since = since; self.tty = tty; self.project = project
        self.sessionID = sessionID; self.counts = counts; self.hooksInstalled = hooksInstalled
    }
}

public enum SignalReader {
    /// The filter every reader downstream of the hook files must apply: a record only counts if
    /// its terminal still exists (`live`) and its timestamp is neither too old nor from the
    /// future. The future check mirrors StateResolver.resolve exactly — a negative age would
    /// otherwise pass `age < staleAfter` forever and pin a bad clock's session as "fresh" for
    /// good.
    public static func liveRecords(_ records: [String: HookRecord], live: Set<String>, now: Date,
                                   staleAfter: TimeInterval = StateResolver.staleAfterDefault)
        -> [HookRecord] {
        records.values.filter { record in
            guard live.contains(record.tty) else { return false }
            let age = now.timeIntervalSince(record.timestamp)
            return age >= 0 && age < staleAfter
        }
    }

    /// Collapse every surviving record to the one signal a badge needs.
    ///
    /// `hooksInstalled` reads the RAW dictionary, before filtering — a directory whose hook files
    /// are all stale or belong to closed tabs is still an instrumented machine (its `state` ends
    /// up `.unknown`, same as a bare directory would), and the two must not be confused; see the
    /// doc on `Signal.hooksInstalled`.
    public static func read(records: [String: HookRecord], live: Set<String>, now: Date,
                            staleAfter: TimeInterval = StateResolver.staleAfterDefault) -> Signal {
        let hooksInstalled = !records.isEmpty
        let surviving = liveRecords(records, live: live, now: now, staleAfter: staleAfter)

        var counts: [SessionState: Int] = [:]
        for record in surviving { counts[record.state, default: 0] += 1 }

        guard let worst = surviving.map(\.state).min() else {
            return Signal(state: .unknown, since: nil, tty: nil, project: nil, sessionID: nil,
                         counts: counts, hooksInstalled: hooksInstalled)
        }

        // Tie-break: oldest timestamp among the worst-state records — whichever session has sat
        // in that state longest. Left to Dictionary's undefined iteration order instead, the
        // winning tty/project would flicker between two reads of the exact same on-disk state.
        let winner = surviving.filter { $0.state == worst }.min { $0.timestamp < $1.timestamp }!

        return Signal(state: worst, since: winner.timestamp, tty: winner.tty,
                     project: project(cwd: winner.cwd), sessionID: winner.sessionID,
                     counts: counts, hooksInstalled: hooksInstalled)
    }

    /// Last path component of a hook's `cwd`. Not `NSString.lastPathComponent` verbatim: that
    /// method treats "/" as its own last component instead of "no project", and every caller here
    /// needs the no-project case to collapse cleanly to `nil` rather than to a slash-shaped string
    /// nothing displays.
    public static func project(cwd: String?) -> String? {
        guard var path = cwd, !path.isEmpty else { return nil }
        if path.hasSuffix("/") { path.removeLast() }
        guard !path.isEmpty, let slash = path.lastIndex(of: "/") else {
            return path.isEmpty ? nil : path
        }
        return String(path[path.index(after: slash)...])
    }

    /// idle 0 and unknown 0 both mean "nothing to report, that's fine" for a shell script's `$?`.
    /// 1 stays out of this switch on purpose: it is "the chute command itself failed" everywhere
    /// else in this CLI (`Out.fail`, Args.swift:61-63), and reusing it for "blocked" would make
    /// `chute signal; echo $?` indistinguishable from a crash.
    public static func exitCode(_ state: SessionState) -> Int32 {
        switch state {
        case .idle:    return 0
        case .blocked: return 10
        case .waiting: return 11
        case .working: return 12
        case .unknown: return 0
        }
    }

    /// Five distinct answers for five distinct situations — collapsing any two of them repeats
    /// the badge bug this whole file exists to not repeat:
    ///   "blocked 22 min · 37.chute"  — a real, fresh, urgent state, with its duration and where.
    ///   "shell · 37.chute"           — real and fresh, just not urgent (idle has no duration
    ///                                   worth printing; see SessionPhrasing.held below).
    ///   "nothing running"            — hooks exist, nothing currently live.
    ///   "hooks not installed"        — Chute is BLIND on this machine, not calm.
    public static func phrase(_ s: Signal, now: Date) -> String {
        guard s.hooksInstalled else { return "hooks not installed" }
        guard s.state != .unknown else { return "nothing running" }
        // SessionPhrasing.held already builds "blocked 22 min" verbatim — StatusMenu.swift reuses
        // it for the identical reason ("the duration IS the product") — but it deliberately
        // returns "" for `.idle`: a shell with no agent has not been "idle for 4 h" in any sense
        // worth a reader's attention. Fall back to the plain state label for that one case.
        let held = SessionPhrasing.held(s.state, since: s.since, now: now)
        let head = held.isEmpty ? s.state.label.lowercased() : held
        guard let project = s.project else { return head }
        return "\(head) · \(project)"
    }

    /// Keys are OMITTED rather than null for anything optional — the same convention
    /// SessionCommands.swift:52-59 already uses, so a consumer checking `row["project"] != nil`
    /// gets a straight answer instead of also having to handle JSON null.
    public static func json(_ s: Signal, now: Date) -> [String: Any] {
        // HookState.stateName collapses `.unknown` to "idle" (HookState.swift:76-84) because a
        // FILE ON DISK can never legally say "unknown" — parse() only ever recognises
        // blocked/waiting/working/idle. Signal's entire reason to exist is telling ".unknown, no
        // evidence" apart from ".idle, evidence says calm", so the JSON contract keeps its own
        // word for it here rather than inheriting HookState's collapse.
        let stateName = s.state == .unknown ? "unknown" : HookState.stateName(s.state)
        var countsByName: [String: Int] = [:]
        for (state, n) in s.counts { countsByName[HookState.stateName(state)] = n }

        var row: [String: Any] = [
            "state": stateName,
            "seconds": s.since.map { Int(now.timeIntervalSince($0)) } ?? 0,
            "counts": countsByName,
            "hooksInstalled": s.hooksInstalled,
        ]
        if let project = s.project { row["project"] = project }
        if let tty = s.tty { row["tty"] = tty }
        if let sessionID = s.sessionID { row["sessionId"] = sessionID }
        return row
    }
}

/// tty liveness — the other half of "live AND fresh" that `SignalReader.liveRecords` filters on.
/// A hook file outlives the terminal tab that wrote it (up to `staleAfter`), so a closed tab's
/// last "waiting" sits on disk claiming to need you until something checks whether its tty is
/// still attached to a process. This used to be an orphaned doc comment (HookState.swift:72-75)
/// for a helper that got deleted before it was written — cut off mid-sentence on "never an". This
/// is that helper, restated from scratch. It stays out of HookState.swift itself only because this
/// change is scoped to two new files, not because it belongs anywhere else.
///
/// Lives as an extension on `HookState` rather than a `static` on `SignalReader` because it reads
/// as part of the same "what does the hook layer currently know" question `HookState.readAll`
/// answers — `SignalReader` only ever consumes ttys, it does not produce them.
public extension HookState {
    /// PURE — parses `ps -Ao tty=` output, so the parsing logic is testable without running `ps`.
    /// `??` is `ps`'s spelling for "no controlling terminal" (a daemon, a launchd job, `cron`);
    /// blank lines show up because the real output ends in a trailing newline. Neither is a live
    /// terminal tab.
    static func ttyNames(psOutput: String) -> Set<String> {
        var out = Set<String>()
        for line in psOutput.split(separator: "\n", omittingEmptySubsequences: false) {
            let tty = line.trimmingCharacters(in: .whitespaces)
            guard !tty.isEmpty, tty != "??" else { continue }
            out.insert(Session.normalise(tty: tty))
        }
        return out
    }

    /// The one-line impure wrapper. Everything that can go wrong — `ps` missing, empty output,
    /// a non-zero exit — is already absorbed by `Shell.run` (NFR-11: a missing tool degrades to
    /// an empty result, never a crash) and by `ttyNames` itself, so there is nothing left here
    /// worth a test that `ttyNames` doesn't already cover without shelling out.
    static func liveTTYs() -> Set<String> {
        ttyNames(psOutput: Shell.run("ps", ["-Ao", "tty="]).out)
    }
}
