import Foundation

/// FR-11 / FR-17 / FR-18 — the rules and prompts a builder otherwise re-copies from old repos.
public enum Templates {
    public static let all = ["claude", "cursor", "agents", "scratchpad", "gitignore"]

    public static func fileName(for rule: String) -> String? {
        switch rule {
        case "claude":     return "CLAUDE.md"
        case "cursor":     return ".cursorrules"
        case "agents":     return "AGENTS.md"
        case "scratchpad": return "SCRATCHPAD.md"
        case "gitignore":  return ".gitignore"
        default:           return nil
        }
    }

    public static func body(for rule: String, project: String) -> String? {
        switch rule {
        case "claude", "agents": return agentRules(project: project)
        case "cursor":           return cursorRules
        case "scratchpad":       return scratchpad(project: project)
        case "gitignore":        return gitignore
        default:                 return nil
        }
    }

    static func agentRules(project: String) -> String {
        """
        # \(project)

        ## Ground rules
        - Read before you write. Trace the actual flow end to end before editing.
        - Smallest change that works. No abstraction with one implementation, no config for a
          value that never changes, no scaffolding "for later".
        - Fix the root cause, not the symptom. Grep every caller before patching one.
        - Never mutate an input — return a new value.
        - Handle errors explicitly. Never silently swallow.
        - Validate at every boundary: user input, API responses, file content.

        ## Before you claim done
        - Run the check. Read its tally, not its exit code. Silence is not a pass.
        - Perturb a new guard until it fails, then restore it. A green you never saw go red
          is not evidence.
        - State what you skipped and why.

        ## Files
        - 200–400 lines typical, 800 hard maximum. Functions under 50 lines.
        - Organise by feature, not by type.
        """
    }

    static let cursorRules = """
        Be the laziest senior developer who has been paged at 3am for over-engineered code.

        1. Does this need to exist at all? Speculative need = skip it.
        2. Does something in this codebase already do it? Reuse it.
        3. Does the standard library do it? Use it.
        4. Does a native platform feature cover it? Prefer it over a dependency.
        5. Can it be one line? Make it one line.
        6. Only then: the minimum code that works.

        Boring over clever. Deletion over addition. Shortest working diff wins — but only after
        you understand the problem. The smallest change in the wrong place is a second bug.

        Never simplify away: input validation, error handling that prevents data loss, security,
        accessibility, or anything explicitly requested.
        """

    static func scratchpad(project: String) -> String {
        """
        # SCRATCHPAD — \(project)

        Working memory. Append-only. The top entry is where you are right now.

        """
    }

    static let gitignore = """
        .DS_Store
        node_modules/
        .build/
        dist/
        .env
        .env.*
        !.env.example
        *.log
        """

    // MARK: - Prompts (FR-17, FR-18)

    public static let decomposePrompt = """
        Break the work below into tasks that each take an agent about 15 minutes.

        For every task give exactly:
        - Goal — one sentence, in terms of observable behaviour, not implementation.
        - Files — the absolute paths it touches. If two tasks touch the same file, merge them.
        - Verification — the one command that proves it works, and the output line to look for.
        - Done when — a binary condition. No "mostly", no "should".

        Rules:
        - Order by dependency; say plainly what blocks what.
        - Anything you cannot make verifiable is not a task — it is a question. List those
          separately under OPEN QUESTIONS.
        - No task may be "refactor X" without a behavioural reason.

        WORK:
        """

    public static let ponytailPrompt = """
        Review your last proposal as a senior engineer who has been paged at 3am for exactly this
        kind of code. Cut it down.

        For each piece, answer in one line: keep, or delete and why.
        - Any interface with one implementation → delete it.
        - Any factory, manager, helper, or wrapper that adds no behaviour → delete it.
        - Any config value that never changes → inline it.
        - Anything the standard library or the platform already does → use theirs.
        - Anything built for a requirement nobody stated → delete it.

        Then give me the version with roughly half the lines. If you cannot halve it, say which
        specific requirement forces the size — name the requirement, do not argue in general terms.

        Do not simplify away: input validation, error handling that prevents data loss, security
        controls, or accessibility.
        """
}
