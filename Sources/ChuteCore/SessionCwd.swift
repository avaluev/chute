import Foundation

/// WHICH DIRECTORY A TERMINAL TAB IS IN — for every tab, not just the instrumented ones.
///
/// A tty is not one process, it is a tree of them: the shell, the agent it launched, and whatever
/// those spawned. They frequently disagree about the working directory, so "the cwd of this tab"
/// needs a rule, and the rule has a wrong answer available to it. That is why this file is pure
/// and sits in ChuteCore: `Sources/ChuteApp/` cannot be linked by the suite, and every derivation
/// that has ever lived there shipped a bug nothing could see.
///
/// THE RULE, IN ORDER:
///
///   1. **A known agent process wins.** It is the thing the row is about. If you `cd` in the
///      shell while Claude Code works two directories away, the row should follow the agent —
///      the agent is what is editing files and what will stop to ask you something.
///   2. **Otherwise the shell.** A tab with no agent is a shell, and the shell's cwd is the tab's.
///   3. **Otherwise anything left on the tty**, so a tab running a bare process still resolves.
///
/// Ties inside a tier break on the LOWEST pid, which is the oldest process. Not for correctness —
/// any of them would do — but because `Dictionary` iteration order is undefined, and without a
/// tie-break the project name on a row would flicker between two reads of identical system state.
/// That exact class of flicker is why `SignalReader.read` sorts its winner too.
public enum SessionCwd {
    /// Pure. `cwdOf` is injected because it is a syscall, and a suite must be able to answer it
    /// from a dictionary instead. `ProcessIdentity.workingDirectory` is the real one.
    public static func map(_ processes: [ProcessSample],
                           cwdOf: (Int32) -> String?,
                           isAgent: (String) -> Bool = { TerminalAppAdapter.agentName(in: $0) != nil })
        -> [String: String] {
        var best: [String: (rank: Int, pid: Int, cwd: String)] = [:]
        for p in processes where !p.tty.isEmpty {
            // 0 beats 1 beats 2 — see THE RULE above.
            let rank = isAgent(p.command) ? 0 : (isShell(p.command) ? 1 : 2)
            guard let cwd = cwdOf(Int32(p.pid)), cwd != "/" else { continue }
            let candidate = (rank: rank, pid: p.pid, cwd: cwd)
            let current = best[p.tty]
            // `<` on the tuple gives "better rank, then lower pid" in one comparison, the same
            // trick StatusMenu's sort uses.
            if current == nil || (candidate.rank, candidate.pid) < (current!.rank, current!.pid) {
                best[p.tty] = candidate
            }
        }
        return best.mapValues(\.cwd)
    }

    /// The shells a terminal tab actually runs. Matched on the basename the kernel reports, which
    /// is why `-zsh` (a login shell, argv[0] prefixed with a dash) has to be handled: that is the
    /// normal shape of the FIRST process in a Terminal.app tab, not an edge case.
    static let shells = ["zsh", "bash", "fish", "sh", "dash", "ksh", "tcsh", "csh", "nu", "xonsh"]

    public static func isShell(_ command: String) -> Bool {
        let name = command.hasPrefix("-") ? String(command.dropFirst()) : command
        return shells.contains((name as NSString).lastPathComponent)
    }
}
