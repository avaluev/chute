import Foundation

/// One name, derived one way, for both surfaces that show it.
///
/// Before this file: the badge derived a session's name from `SignalReader.project(cwd:)` (the
/// hook's `cwd`, authoritative) while the menu derived it from
/// `TerminalAppAdapter.project(fromWindowName:)` (Terminal's window title — a string another
/// process writes and the user can reconfigure in Terminal's preferences). Nothing kept the two in
/// sync, so the badge and the menu could name the SAME session two different things, and nothing
/// in the UI let a user notice. This is the one place that decision now lives; Phase 1c forwards
/// both call sites here so there is only one derivation left to get wrong.
public enum ProjectName {
    /// PURE — the git probe is injected, so no test here touches a filesystem.
    ///
    /// `gitRoot` is asked about `cwd` itself, ONCE. `ProjectRoot.gitTopLevel` walks the filesystem
    /// with `stat` calls, and this function runs per session, on every menu open — a second call
    /// (say, retried against some derived path) would double that cost for every row, on every
    /// refresh, for no benefit: the first call already answers definitively for `cwd`.
    ///
    /// Priority, each step a fallback for the one before it coming up empty:
    ///   1. the git repository root's leaf name — `/a/b/repo` and `/a/b/repo/site` MUST return the
    ///      same name, because they are the same project. That identical return is the bug this
    ///      file exists to fix; see `T.eq(... "THE BUG: ...")` in PathAbbrevSuite.
    ///   2. the cwd's own leaf, when there is no git root — the hook still names a working
    ///      directory even outside a repo, and that beats guessing from a window title.
    ///   3. the terminal window-title head — exactly what the derivation used before this file,
    ///      kept as the last resort for sessions Chute has no cwd for at all.
    ///   4. `nil`. "Nothing derived" is data, not a sentinel string — see `of` below.
    public static func resolve(cwd: String?, windowTitle: String,
                               gitRoot: (String) -> String?) -> String? {
        // ONLY AN ABSOLUTE PATH IS EVIDENCE. The hook writes `$PWD`, which is always absolute —
        // so anything else here means the data is wrong, and the question is what a WRONG cwd is
        // allowed to put on screen. `leaf(of:)` would happily answer "path" for `relative/path`
        // and "~" for a shell that wrote the tilde literally, and the menu would then print a
        // confident project name derived from a string Chute cannot resolve to any location on
        // disk. That is the exact failure this file exists to end, arriving through a different
        // door. `hasPrefix("/")` rejects the empty string and the bare tilde in the same test.
        if let cwd, cwd.hasPrefix("/") {
            if let root = gitRoot(cwd), let leaf = leaf(of: root) { return leaf }
            if let leaf = leaf(of: cwd) { return leaf }
        }
        return titleHead(windowTitle)
    }

    /// The one impure call site: wires the real filesystem probe in.
    ///
    /// `ProjectRoot.gitTopLevel` has no access modifier, so it is `internal` — and a `public`
    /// function cannot default an argument to an internal symbol. Swift requires a default
    /// argument's expression to be at least as visible as the function it defaults on, because the
    /// default is logically part of the public interface a caller outside this module relies on,
    /// even though it is evaluated inside this module. So `resolve` above takes the probe as a
    /// REQUIRED parameter, and it is supplied here instead, inside a function body — where
    /// visibility rules that govern default-argument expressions simply don't apply.
    public static func of(cwd: String?, windowTitle: String = "") -> String? {
        resolve(cwd: cwd, windowTitle: windowTitle, gitRoot: ProjectRoot.gitTopLevel)
    }

    /// Terminal window names read "36.macai — ◑ Chut — caffeinate ◂ claude — 245×76"; the first
    /// em-dash segment is the working directory's leaf. Moved here verbatim from
    /// `TerminalAppAdapter.project(fromWindowName:)`, with one change: this returns `nil` for
    /// "nothing there" instead of that function's `"—"` placeholder — `ProjectName` speaks in
    /// `String?` everywhere, and a directory can legitimately be named `—`, so a sentinel would
    /// make a REAL project named `—` indistinguishable from no project at all.
    public static func titleHead(_ name: String) -> String? {
        let head = name.components(separatedBy: " — ").first?
            .trimmingCharacters(in: .whitespaces) ?? ""
        return head.isEmpty ? nil : head
    }

    /// Last path component, trailing slash stripped first, `"/"` collapsing to `nil` rather than
    /// to a slash-shaped string nothing displays — the same rule `SignalReader.project(cwd:)`
    /// (Signal.swift:105-112) uses today, restated here because that IS the leaf logic this file
    /// generalises. Phase 1c forwards `SignalReader.project` to `ProjectName.of`, so after that
    /// lands there is only one copy of this rule left.
    private static func leaf(of path: String) -> String? {
        // EVERY trailing slash, not one. Stripping a single slash left "/a/b//" as "/a/b/", whose
        // last component — the text after the final slash — is the EMPTY STRING. That returned
        // `Optional("")`, which is not nil, so every "no project derived" check downstream waved it
        // through as a real name and the row printed a blank where a project belongs. A blank is
        // the one thing worse than "no project derived": it looks like a rendering fault rather
        // than a fact. Same reason for the final emptiness test below.
        var trimmed = path
        while trimmed.hasSuffix("/") { trimmed.removeLast() }
        guard !trimmed.isEmpty else { return nil }
        guard let slash = trimmed.lastIndex(of: "/") else { return trimmed }
        let name = String(trimmed[trimmed.index(after: slash)...])
        return name.isEmpty ? nil : name
    }
}
