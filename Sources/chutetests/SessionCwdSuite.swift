import Foundation
import ChuteCore

/// THE EIGHT ROWS THAT READ `no project derived` WHILE THE TAB BESIDE THEM SHOWED THE PATH.
///
/// Antigravity ships no hooks, so `hook?.cwd` is nil for every one of its sessions, and Terminal's
/// window name is the directory LEAF — never a path — so there was nothing to resolve a git root
/// against. The kernel knew all along. These are the rules that use it.
func sessionCwdSuite() {
    T.suite("SessionCwd") {
        func p(_ pid: Int, _ tty: String, _ command: String) -> ProcessSample {
            ProcessSample(pid: pid, ppid: 1, command: command, tty: tty,
                          cpuPercent: 0, residentKB: 0)
        }

        // ── RULE 1: THE AGENT WINS ──────────────────────────────────────────────────────────
        // `cd` in the shell while Claude Code works two directories away and the row must follow
        // the AGENT: it is the thing editing files and the thing that will stop to ask you
        // something. The shell is where you happen to be standing.
        let dirs = [100: "/repo", 200: "/repo/site"]
        let tab = [p(100, "ttys001", "-zsh"), p(200, "ttys001", "claude")]
        T.eq(SessionCwd.map(tab, cwdOf: { dirs[Int($0)] }), ["ttys001": "/repo/site"],
             "the agent's directory is the tab's, not the shell's")

        // ── RULE 2: OTHERWISE THE SHELL ─────────────────────────────────────────────────────
        // A tab with no agent still has a project, and a `node` running in it is not the answer.
        let plain = [p(300, "ttys002", "-zsh"), p(400, "ttys002", "node")]
        T.eq(SessionCwd.map(plain, cwdOf: { $0 == 300 ? "/shell" : "/node" }),
             ["ttys002": "/shell"], "with no agent, the shell speaks for the tab")

        // ── RULE 3: OTHERWISE ANYTHING ──────────────────────────────────────────────────────
        T.eq(SessionCwd.map([p(500, "ttys003", "vim")], cwdOf: { _ in "/anywhere" }),
             ["ttys003": "/anywhere"], "a tab running neither shell nor agent still resolves")

        // ── DETERMINISM ─────────────────────────────────────────────────────────────────────
        // Dictionary iteration order is undefined. Without the pid tie-break the project name on
        // a row would flicker between two reads of identical system state — the same failure
        // SignalReader.read sorts its winner to avoid.
        let twins = [p(900, "ttys004", "claude"), p(800, "ttys004", "claude")]
        let a = SessionCwd.map(twins, cwdOf: { $0 == 800 ? "/older" : "/newer" })
        let b = SessionCwd.map(twins.reversed(), cwdOf: { $0 == 800 ? "/older" : "/newer" })
        T.eq(a, b, "the same processes always give the same answer, whatever the listing order")
        T.eq(a, ["ttys004": "/older"], "and the tie goes to the oldest process, not to luck")

        // ── WHAT MUST NOT RESOLVE ───────────────────────────────────────────────────────────
        T.eq(SessionCwd.map([p(1, "", "launchd")], cwdOf: { _ in "/" }), [:],
             "a process with no controlling terminal belongs to no tab")
        T.eq(SessionCwd.map([p(2, "ttys005", "zsh")], cwdOf: { _ in "/" }), [:],
             "the root directory is not a project — it is the answer you get when you know nothing")
        T.eq(SessionCwd.map([p(3, "ttys006", "zsh")], cwdOf: { _ in nil }), [:],
             "a pid the kernel will not answer for is left out, never guessed at")

        // A shell that cannot be read must not stop an agent on the same tty from being found.
        let halfBlind = [p(10, "ttys007", "-zsh"), p(11, "ttys007", "agy")]
        T.eq(SessionCwd.map(halfBlind, cwdOf: { $0 == 11 ? "/found" : nil }),
             ["ttys007": "/found"], "one unreadable process does not blind the whole tab")

        // ── LOGIN SHELLS ────────────────────────────────────────────────────────────────────
        // argv[0] of the first process in a Terminal.app tab is "-zsh", with the dash. That is
        // the NORMAL shape here, not an edge case, and missing it would demote every shell to
        // rule 3 and let a stray `node` outrank it.
        T.ok(SessionCwd.isShell("-zsh"), "a login shell is a shell")
        T.ok(SessionCwd.isShell("/bin/bash"), "and so is one named by full path")
        T.ok(SessionCwd.isShell("fish"), "fish counts")
        T.no(SessionCwd.isShell("claude"), "an agent is not a shell")
        T.no(SessionCwd.isShell("zshfoo"), "and neither is something that merely starts with one")

        // ── THE REAL SHAPE, END TO END ──────────────────────────────────────────────────────
        // The founder's own machine, 2026-09-08: an Antigravity tab whose hook does not exist.
        // Before this file it read `no project derived`; the git root turns the deep path into
        // the project the reader recognises.
        let agy = [p(92080, "ttys010", "-zsh"), p(92264, "ttys010", "agy")]
        let deep = "/Users/x/Documents/2026/Development/5.STNZ.AI/sntz_mockups/docs/DemoSeptember"
        let resolved = SessionCwd.map(agy, cwdOf: { _ in deep })["ttys010"]
        T.eq(resolved, deep, "a hookless Antigravity tab resolves to a real directory")
        T.eq(ProjectName.resolve(cwd: resolved, windowTitle: "Terminal",
                                 gitRoot: { $0.hasPrefix("/Users/x/Documents/2026/Development/5.STNZ.AI/sntz_mockups")
                                            ? "/Users/x/Documents/2026/Development/5.STNZ.AI/sntz_mockups" : nil }),
             "sntz_mockups",
             "and a subdirectory of the repo still names the repo, not the subdirectory")
    }
}

/// The two cells that could go blank rather than say what they knew.
func phrasingGapsSuite() {
    T.suite("SessionPhrasing gaps") {
        let now = Date(timeIntervalSince1970: 1_757_000_000)

        // A BLOCKED SESSION IS THE WHOLE PRODUCT. Losing the word because the timestamp is
        // missing or skewed leaves the state column empty, which reads as "Chute knows nothing"
        // — the opposite of what it knows.
        T.eq(SessionPhrasing.held(.blocked, since: nil, now: now), "blocked",
             "with no timestamp the state still shows; only the duration is withheld")
        T.eq(SessionPhrasing.held(.blocked, since: now.addingTimeInterval(3600), now: now),
             "blocked", "a future timestamp is clock skew — drop the duration, keep the fact")
        T.eq(SessionPhrasing.held(.waiting, since: nil, now: now), "ready",
             "same for ready")
        T.eq(SessionPhrasing.held(.working, since: nil, now: now), "working",
             "and for working")
        T.eq(SessionPhrasing.held(.blocked, since: now.addingTimeInterval(-120), now: now),
             "blocked 2 min", "a trustworthy timestamp still carries its duration")

        // Unchanged on purpose: a state Chute makes no claim about says nothing, and a shell has
        // not been "idle for 4 h" in any sense a reader cares about.
        T.eq(SessionPhrasing.held(.idle, since: nil, now: now), "",
             "idle still says nothing — that rule predates this one and outranks it")
        T.eq(SessionPhrasing.held(.unknown, since: now, now: now), "",
             "and so does a state Chute admits it cannot see")

        // An empty agent string is not an agent.
        T.eq(SessionPhrasing.detail(agent: "", transcript: nil), "no agent running",
             "an empty agent name is no agent, not a blank cell")
        T.eq(SessionPhrasing.detail(agent: nil, transcript: nil), "no agent running",
             "and nil reads the same way")
        T.eq(SessionPhrasing.detail(agent: "claude", transcript: nil), "Claude Code",
             "a real agent is unaffected")
    }
}

/// THREE DIFFERENT FACTS THAT USED TO SHARE ONE SENTENCE.
///
/// Every `.unknown` row read "no hook — Chute cannot see this". True of Antigravity, and WRONG
/// about Claude Code on a machine whose hooks are wired: on 2026-09-08 the founder's menu showed
/// ten of them, six being Claude Code sessions with all four hooks installed and reporting. They
/// had simply not reached a turn boundary since their records were deleted. The row sent the
/// reader to fix something that was not broken, which is worse than saying nothing.
func unknownReasonSuite() {
    T.suite("unknownReason") {
        T.eq(SessionPhrasing.unknownReason(agent: "agy", hooksWired: true),
             "no hook — Chute cannot see this",
             "Antigravity ships no hooks: permanent, and nothing the reader can do")
        T.eq(SessionPhrasing.unknownReason(agent: "agy", hooksWired: false),
             "no hook — Chute cannot see this",
             "and wiring Claude Code's hooks would not change that, so it must not be implied")

        T.eq(SessionPhrasing.unknownReason(agent: "claude", hooksWired: true),
             "hooks wired — nothing reported yet",
             "a wired Claude Code session has not reported YET — it is not misconfigured")
        T.eq(SessionPhrasing.unknownReason(agent: "claude", hooksWired: false),
             "hooks not wired — open Setup…",
             "and this is the one case that IS the reader's to fix, so it names the door")

        // Only Claude Code can report at all: Chute's hooks ARE Claude Code's hooks.
        T.eq(SessionPhrasing.hookCapableAgents, ["claude"],
             "one agent can report a state; claiming otherwise would blame the wrong thing")
        for other in ["codex", "cursor", "gemini", "aider"] {
            T.eq(SessionPhrasing.unknownReason(agent: other, hooksWired: true),
                 "no hook — Chute cannot see this",
                 "\(other) has no hook mechanism here, wired or not")
        }
        T.eq(SessionPhrasing.unknownReason(agent: nil, hooksWired: true),
             "no hook — Chute cannot see this",
             "and no agent at all falls to the same honest answer")
    }
}
