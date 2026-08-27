import Foundation
import ChuteCore

func sessionSuite() {
    T.suite("Session") {
        T.eq(Session.normalise(tty: "/dev/ttys004"), "ttys004", "strips /dev prefix")
        T.eq(Session.normalise(tty: "ttys004"), "ttys004", "already normalised is unchanged")
        T.eq(Session.makeKey(kind: .terminalApp, windowID: 207250, tty: "/dev/ttys004"),
             "Terminal:207250:ttys004", "stable session key")
        T.ok(SessionState.blocked < SessionState.waiting, "blocked outranks waiting")
        T.ok(SessionState.waiting < SessionState.idle, "waiting outranks idle")
        T.eq(SessionState.blocked.label, "BLOCKED", "label")

        // WORDING. Every number in the menu must say what it counts. "3h" and "2%" did not, and a
        // menu is read, not parsed — so these are checked as sentences, not as formats.
        let now = Date()
        T.eq(SessionPhrasing.waitedFor(now.addingTimeInterval(-30)), "just asked you",
             "a fresh prompt reads as an event, not as '0m'")
        T.eq(SessionPhrasing.waitedFor(now.addingTimeInterval(-60)), "waiting 1 minute for you",
             "singular minute")
        T.eq(SessionPhrasing.waitedFor(now.addingTimeInterval(-25 * 60)), "waiting 25 minutes for you",
             "minutes are spelled out")
        T.eq(SessionPhrasing.waitedFor(now.addingTimeInterval(-60 * 60)), "waiting 1 hour for you",
             "singular hour")
        T.eq(SessionPhrasing.waitedFor(now.addingTimeInterval(-3 * 3600)), "waiting 3 hours for you",
             "and '3h' now says what the 3 counts")
        T.eq(SessionPhrasing.waitedFor(nil), "waiting for you",
             "with no timestamp it still says what is happening")

        for phrase in [SessionPhrasing.waitedFor(now.addingTimeInterval(-3 * 3600)),
                       SessionPhrasing.runningFor(now.addingTimeInterval(-90 * 60))] {
            T.ok(phrase.rangeOfCharacter(from: CharacterSet.letters) != nil,
                 "'\(phrase)' carries words, not just digits")
        }

        // The load label names its unit.
        let busy = SessionLoad(cpuPercent: 12.4, residentBytes: 1_610_612_736, processes: 3)
        T.eq(busy.label, "12% CPU · 1.5 GB", "the percentage says what it measures")

        // Thermal wording is for a person, not an instrument panel.
        T.eq(SystemVitals.thermalPressure(.nominal), "running cool", "plain words")
        T.ok(SystemVitals.thermalPressure(.critical).contains("slowing down"),
             "and the worst case says what it means for the work, not just its severity")
    }
}
