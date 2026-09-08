import Foundation
import ChuteCore

func signalSuite() {
    T.suite("Signal") {
        let now = Date(timeIntervalSince1970: 1_756_300_000)

        func rec(_ tty: String, _ state: SessionState, cwd: String? = nil,
                sessionID: String? = nil, secondsAgo: Double = 60) -> HookRecord {
            HookRecord(tty: tty, state: state, cwd: cwd, sessionID: sessionID,
                      timestamp: now.addingTimeInterval(-secondsAgo))
        }

        // ── ZERO RECORDS: BLIND, NOT CALM ───────────────────────────────────────────────
        let empty = SignalReader.read(records: [:], live: [], now: now)
        T.eq(empty.state, .unknown, "no records at all reads as unknown")
        T.no(empty.hooksInstalled, "an empty hook directory means Chute is blind")
        T.ok(empty.since == nil, "blind carries no since")
        T.ok(empty.tty == nil, "blind carries no tty")

        // ── ALL IDLE — REAL, FRESH, JUST NOT URGENT ─────────────────────────────────────
        let idleRecords: [String: HookRecord] = [
            "ttys001": rec("ttys001", .idle), "ttys002": rec("ttys002", .idle),
            "ttys003": rec("ttys003", .idle),
        ]
        let idleLive: Set<String> = ["ttys001", "ttys002", "ttys003"]
        let idleSignal = SignalReader.read(records: idleRecords, live: idleLive, now: now)
        T.eq(idleSignal.state, .idle, "three idle sessions read as idle")
        T.eq(idleSignal.counts[.idle], 3, "all three tallied")
        T.ok(idleSignal.hooksInstalled, "idle machine is still instrumented")

        // ── 1 BLOCKED + 3 WORKING => BLOCKED, COUNTS EXACT ──────────────────────────────
        let mixed: [String: HookRecord] = [
            "ttysB": rec("ttysB", .blocked), "ttysW1": rec("ttysW1", .working),
            "ttysW2": rec("ttysW2", .working), "ttysW3": rec("ttysW3", .working),
        ]
        let mixedLive: Set<String> = ["ttysB", "ttysW1", "ttysW2", "ttysW3"]
        let mixedSignal = SignalReader.read(records: mixed, live: mixedLive, now: now)
        T.eq(mixedSignal.state, .blocked, "one blocked outranks three working")
        T.eq(mixedSignal.counts[.blocked], 1, "one blocked tallied")
        T.eq(mixedSignal.counts[.working], 3, "three working tallied")
        T.eq(mixedSignal.counts.count, 2, "no phantom keys for states nobody is in")

        // ── 1 WAITING + 1 WORKING => WAITING (pins the non-obvious precedence) ──────────
        let ww: [String: HookRecord] = ["ttysA": rec("ttysA", .waiting), "ttysC": rec("ttysC", .working)]
        let wwSignal = SignalReader.read(records: ww, live: ["ttysA", "ttysC"], now: now)
        T.eq(wwSignal.state, .waiting, "green outranks amber, straight out of SessionState.<")

        // ── CLOSED TAB: TTY NOT IN `live` IS IGNORED ────────────────────────────────────
        let closed: [String: HookRecord] = ["ttysGone": rec("ttysGone", .blocked)]
        let closedSignal = SignalReader.read(records: closed, live: ["ttysOther"], now: now)
        T.eq(closedSignal.state, .unknown, "a record for a closed tab is not live")
        T.ok(closedSignal.hooksInstalled, "the hook file existing still means instrumented")

        // ── STALE: 7 HOURS OLD IS IGNORED (staleAfterDefault is 6h) ────────────────────
        let stale: [String: HookRecord] = ["ttysOld": rec("ttysOld", .blocked, secondsAgo: 7 * 3600)]
        let staleSignal = SignalReader.read(records: stale, live: ["ttysOld"], now: now)
        T.eq(staleSignal.state, .unknown, "a 7h-old hook is stale, ignored")

        // ── CLOCK SKEW: A FUTURE TIMESTAMP IS IGNORED ───────────────────────────────────
        let future: [String: HookRecord] = ["ttysFuture": rec("ttysFuture", .blocked, secondsAgo: -100)]
        let futureSignal = SignalReader.read(records: future, live: ["ttysFuture"], now: now)
        T.eq(futureSignal.state, .unknown, "a hook from the future is untrustworthy, ignored")

        // ── `since` IS THE RECORD'S TIMESTAMP, NOT `now` ────────────────────────────────
        let ts = now.addingTimeInterval(-300)
        let single: [String: HookRecord] = ["ttysSolo": HookRecord(tty: "ttysSolo", state: .working,
                                                                    cwd: "/p/proj", timestamp: ts)]
        let singleSignal = SignalReader.read(records: single, live: ["ttysSolo"], now: now)
        T.eq(singleSignal.since, ts, "since is the hook's own timestamp")
        T.ok(singleSignal.since != now, "and specifically not the read time")
        T.eq(singleSignal.tty, "ttysSolo", "winner's tty carried through")
        T.eq(singleSignal.project, "proj", "winner's project derived from its cwd")

        // ── TIE-BREAK: OLDEST TIMESTAMP AMONG EQUAL-STATE RECORDS WINS ──────────────────
        let older = now.addingTimeInterval(-600)
        let newer = now.addingTimeInterval(-30)
        let tie: [String: HookRecord] = [
            "ttysOlder": HookRecord(tty: "ttysOlder", state: .blocked, timestamp: older),
            "ttysNewer": HookRecord(tty: "ttysNewer", state: .blocked, timestamp: newer),
        ]
        let tieSignal = SignalReader.read(records: tie, live: ["ttysOlder", "ttysNewer"], now: now)
        T.eq(tieSignal.tty, "ttysOlder", "the one blocked longest wins the byline")
        T.eq(tieSignal.since, older, "and its timestamp is the one reported")

        // ── liveRecords DIRECTLY: the filter in isolation ───────────────────────────────
        let filterInput: [String: HookRecord] = [
            "ttysKeep": rec("ttysKeep", .working),
            "ttysDrop1": rec("ttysDrop1", .working), // not live
            "ttysDrop2": rec("ttysDrop2", .working, secondsAgo: 8 * 3600), // stale
        ]
        let survivors = SignalReader.liveRecords(filterInput, live: ["ttysKeep"], now: now)
        T.eq(survivors.count, 1, "only the live, fresh record survives")
        T.eq(survivors.first?.tty, "ttysKeep", "and it's the right one")

        // ── project(cwd:) — nil, "", "/", trailing slash, normal ────────────────────────
        T.ok(SignalReader.project(cwd: nil) == nil, "nil cwd has no project")
        T.ok(SignalReader.project(cwd: "") == nil, "empty cwd has no project")
        T.ok(SignalReader.project(cwd: "/") == nil, "bare root has no project")
        // A SYNTHETIC path, not a real one on this machine. `project(cwd:)` now forwards to
        // `ProjectName.of`, which walks the filesystem for a `.git` root — a real absolute path
        // would make this assertion's answer depend on whether THAT path happens to sit inside a
        // repo on whichever machine runs the suite. "/nonexistent-chute-test-root" has no `.git`
        // ancestor anywhere, on any machine, so the cwd-leaf fallback is what fires, always.
        T.eq(SignalReader.project(cwd: "/nonexistent-chute-test-root/37.chute"),
             "37.chute", "normal path takes the last component")
        T.eq(SignalReader.project(cwd: "/nonexistent-chute-test-root/37.chute/"),
             "37.chute", "a trailing slash is stripped first")

        // ── exitCode for all five states ────────────────────────────────────────────────
        T.eq(SignalReader.exitCode(.idle), 0, "idle exits 0")
        T.eq(SignalReader.exitCode(.blocked), 10, "blocked exits 10")
        T.eq(SignalReader.exitCode(.waiting), 11, "waiting exits 11")
        T.eq(SignalReader.exitCode(.working), 12, "working exits 12")
        T.eq(SignalReader.exitCode(.unknown), 0, "unknown exits 0, same as idle")
        T.no(Set([SignalReader.exitCode(.blocked), SignalReader.exitCode(.waiting),
                  SignalReader.exitCode(.working)]).contains(1),
             "1 is never reused — that's reserved for the CLI's own failure")

        // ── json — round-trips, omits nulls, keeps `unknown` as its own word ────────────
        let full = Signal(state: .blocked, since: ts, tty: "ttysSolo", project: "proj",
                          sessionID: "sess-1", counts: [.blocked: 1, .working: 2],
                          hooksInstalled: true)
        let fullDict = SignalReader.json(full, now: now)
        let data = try? JSONSerialization.data(withJSONObject: fullDict)
        T.ok(data != nil, "json survives JSONSerialization.data(withJSONObject:)")
        let decoded = data.flatMap { try? JSONSerialization.jsonObject(with: $0) as? [String: Any] }
        T.eq(decoded?["state"] as? String, "blocked", "state round-trips")
        T.eq(decoded?["seconds"] as? Int, 300, "seconds computed from since vs now")
        T.eq(decoded?["project"] as? String, "proj", "project round-trips")
        T.eq(decoded?["sessionId"] as? String, "sess-1", "sessionId round-trips")
        T.eq((decoded?["counts"] as? [String: Int])?["blocked"], 1, "counts keyed by state name")
        T.eq((decoded?["counts"] as? [String: Int])?["working"], 2, "every surviving state tallied")
        T.no(fullDict.values.contains { $0 is NSNull }, "no NSNull anywhere in the row")

        let blind = Signal(state: .unknown, since: nil, tty: nil, project: nil, sessionID: nil,
                           counts: [:], hooksInstalled: false)
        let blindDict = SignalReader.json(blind, now: now)
        T.eq(blindDict["state"] as? String, "unknown",
             "unknown keeps its own word, not HookState's 'idle' collapse")
        T.eq(blindDict["seconds"] as? Int, 0, "no since means 0 seconds, not omitted")
        T.eq(blindDict["hooksInstalled"] as? Bool, false, "blind machine reported as blind")
        T.ok(blindDict["project"] == nil, "nil project is an absent key, not a null value")
        T.ok(blindDict["tty"] == nil, "nil tty is an absent key")
        T.ok(blindDict["sessionId"] == nil, "nil sessionId is an absent key")
        T.no(blindDict.values.contains { $0 is NSNull }, "no NSNull on the blind row either")

        // ── ttyNames(psOutput:) — pure ps parser ────────────────────────────────────────
        let ps = "ttys004\n??\n\nttys009\n"
        T.eq(HookState.ttyNames(psOutput: ps), ["ttys004", "ttys009"], "?? and blanks rejected")
        T.eq(HookState.ttyNames(psOutput: "/dev/ttys004\n"), ["ttys004"], "/dev/ prefix stripped")
        T.eq(HookState.ttyNames(psOutput: "  ttys077  \n"), ["ttys077"], "surrounding whitespace trimmed")
        T.eq(HookState.ttyNames(psOutput: ""), [], "empty ps output is an empty set, not an error")

        // ── phrase — the four calm/urgent/blind wordings ────────────────────────────────
        T.eq(SignalReader.phrase(blind, now: now), "hooks not installed",
             "blind says so, never 'nothing running'")
        let nothingLive = Signal(state: .unknown, since: nil, tty: nil, project: nil,
                                 sessionID: nil, counts: [:], hooksInstalled: true)
        T.eq(SignalReader.phrase(nothingLive, now: now), "nothing running",
             "instrumented but nothing currently live")
        let blockedPhrase = SignalReader.phrase(full, now: now)
        T.ok(blockedPhrase.contains("blocked") && blockedPhrase.contains("proj"),
             "blocked phrase names the state and the project: \(blockedPhrase)")
        let idlePhrase = SignalReader.phrase(idleSignal, now: now)
        T.ok(idlePhrase.hasPrefix("shell"), "idle falls back to the plain label, no fake duration")
    }
}
