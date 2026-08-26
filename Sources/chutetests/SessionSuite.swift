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
    }
}
