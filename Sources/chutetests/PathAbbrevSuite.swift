import Foundation
import ChuteCore

func pathAbbrevSuite() {
    T.suite("PathAbbrev") {
        let home = "/Users/tester"   // a synthetic home — never the real machine's, so the suite
                                      // stays deterministic on the founder's Mac and anyone else's.

        // ── constants, so an accidental edit shows up here first ───────────────────────
        T.eq(PathAbbrev.defaultBudget, 28, "27-29 char reference outputs → 28")
        T.eq(PathAbbrev.defaultNameBudget, 24, "a column budget, not a coincidence")

        // ── trivial inputs — nothing to abbreviate ──────────────────────────────────────
        T.eq(PathAbbrev.path(""), "", "nothing in, nothing out")
        T.eq(PathAbbrev.path("/"), "/", "bare root, unchanged")
        T.eq(PathAbbrev.path("~", home: home), "~", "a literal tilde, already as short as it gets")
        T.eq(PathAbbrev.path("~/a/b", home: home), "~/a/b", "short enough to need no truncation")

        // ── home folding, and its guards ────────────────────────────────────────────────
        T.eq(PathAbbrev.path(home, home: home), "~", "home itself folds to the tilde")
        T.eq(PathAbbrev.path(home + "/", home: home), "~",
             "a trailing slash on home must not produce \"~/\" — it is the same directory")
        T.no(PathAbbrev.path("/Users/tester/inner", home: "/").hasPrefix("~"),
             "HOME=/ must never fold the whole disk to a tilde")

        // ── volumes — only a NAME after \"Volumes\" makes it a root token ──────────────
        T.eq(PathAbbrev.path("/Volumes"), "/Volumes", "no volume name yet — an ordinary path")
        T.eq(PathAbbrev.path("/Volumes/Work"), "/Volumes/Work", "the root token alone, untouched")

        // ── path joining — a doubled slash collapses like any normal path, not one \"…\" ──
        T.eq(PathAbbrev.path("/a//b"), "/a/b", "an empty path segment is not a component")

        // ── relative paths never grow a leading \"/\" they didn't have ─────────────────
        let deepRelative = "some/very/deeply/nested/relative/path/to/a/file.txt"
        T.no(PathAbbrev.path(deepRelative, budget: 15).hasPrefix("/"),
             "abbreviating a relative path must not make it read as absolute")

        // ── a component containing \" — \", the OLD window-title parser's separator ─────
        // PathAbbrev splits on \"/\" only — the em-dash inside a component is just text to it,
        // unlike ProjectName.titleHead which deliberately splits on it. Two different rules.
        T.eq(PathAbbrev.path("/Users/x/proj — beta", budget: 28), "/Users/x/proj — beta",
             "the space-em-dash-space is not a path separator here")

        // ── ONE ENORMOUS COMPONENT, nothing else — the plan's own worked middle() example ──
        T.eq(PathAbbrev.middle("a-very-long-directory", to: 20), "a-very-lo…-directory",
             "head=(n-1)/2, tail=n-1-head — the tail gets the odd character")
        T.eq(PathAbbrev.path("a-very-long-directory", budget: 20), "a-very-lo…-directory",
             "a single component with nothing above it goes straight to middle()")

        // ── THE FOUNDER'S RULING, in a running assertion, not just prose ────────────────
        // /Volumes/Work/a/b/api-gateway at budget 28: the literal \"always keep last two\" rule
        // reads /Volumes/Work/…/b/api-gateway (29 chars, over budget). Dropping \"b\" instead
        // reads /Volumes/Work/…/api-gateway (27 chars) — shorter AND it does not mangle a real
        // word to buy the one character \"b\" was costing. That is the ruling this test pins.
        T.eq(PathAbbrev.path("/Volumes/Work/a/b/api-gateway", budget: 28),
             "/Volumes/Work/…/api-gateway",
             "dropping a whole component beats shaving one character off a kept word")

        // ── ONE ellipsis for the whole middle, never one per dropped component ──────────
        T.eq(PathAbbrev.path("/Users/x/a/b/c/d/e/f/g/leaf", budget: 20)
                .filter { $0 == "…" }.count, 1,
             "ONE ellipsis for the whole middle, never one per component")

        // ── reflow-from-the-left, pinned exactly at its own boundary ────────────────────
        // At budget 19 or 20, \"Users\", \"x\" and \"a\" all still fit ahead of \"…/g/leaf\".
        // Dropping the budget by exactly one character (18) is what stops \"a\" from fitting —
        // proving the greedy re-add stops at the right place, not one component early or late.
        T.eq(PathAbbrev.path("/Users/x/a/b/c/d/e/f/g/leaf", budget: 20), "/Users/x/a/…/g/leaf",
             "budget 20 keeps Users, x AND a ahead of the ellipsis")
        T.eq(PathAbbrev.path("/Users/x/a/b/c/d/e/f/g/leaf", budget: 19), "/Users/x/a/…/g/leaf",
             "19 is still exactly enough for all three")
        T.eq(PathAbbrev.path("/Users/x/a/b/c/d/e/f/g/leaf", budget: 18), "/Users/x/…/g/leaf",
             "one character less and \"a\" no longer fits — the greedy add stops, it does not overshoot")

        // ── root survives via mid-word truncation once dropping alone isn't enough ──────
        let longLeaf = String(repeating: "x", count: 40)
        T.eq(PathAbbrev.path("~/mid/\(longLeaf)", budget: 20),
             "~/…/" + PathAbbrev.middle(longLeaf, to: 16),
             "root+…/ survives; only the leaf itself pays for the overage")

        // ── the root token is dropped too once even a truncated leaf can't share room with it ──
        T.eq(PathAbbrev.path("~/mid/\(longLeaf)", budget: 5),
             "…/" + PathAbbrev.middle(longLeaf, to: 3),
             "budget too tight for root AND leaf — the root goes, the leaf's own edges remain")

        // ── budget smaller than the root token, the absolute last resort ───────────────
        T.eq(PathAbbrev.path("~/a/b", budget: 1, home: home), "b",
             "a budget this small never crashes — the leaf alone, root ignored entirely")

        // ── grapheme-cluster safety: an emoji is one \"character\", never split ─────────
        let familyEmoji = "👨‍👩‍👧‍👦"
        let withEmoji = "abcdefgh" + familyEmoji
        T.eq(withEmoji.count, 9, "a ZWJ emoji sequence counts as ONE grapheme cluster")
        let emojiTruncated = PathAbbrev.middle(withEmoji, to: 5)
        T.ok(emojiTruncated.contains(familyEmoji),
             "the emoji survives whole in the tail — prefix/suffix never split a grapheme cluster")

        // ── grapheme-cluster safety: a combining mark stays attached to its base letter ──
        let combiningE = "e\u{0301}"   // \"é\" as base letter + combining acute — one grapheme
        let withCombining = combiningE + "BBBBBBBB"
        T.eq(withCombining.count, 9, "combining mark + base letter is one grapheme, not two")
        T.ok(PathAbbrev.middle(withCombining, to: 5).hasPrefix("é"),
             "prefix() lands on a grapheme boundary, never inside the combining mark")

        // ── middle() directly — the primitive itself ────────────────────────────────────
        T.eq(PathAbbrev.middle("short", to: 20), "short", "already fits — returned unchanged")
        T.eq(PathAbbrev.middle("anything at all", to: 2), "…",
             "under-3 budget collapses to a bare ellipsis, no partial head or tail")
        T.eq(PathAbbrev.middle("anything at all", to: 0), "…", "a zero budget still never crashes")

        // ── name() — tail truncation, a different rule for a different kind of string ──
        T.eq(PathAbbrev.name("short"), "short", "already fits — returned unchanged")
        T.eq(PathAbbrev.name("A very long display name here", budget: 10), "A very lo…",
             "a name truncates at the TAIL — it is a word, not a path with two ends")
        T.eq(PathAbbrev.name("Alpha Beta Gamma", budget: 7), "Alpha…",
             "trailing whitespace is trimmed before the ellipsis, not left dangling")
        T.eq(PathAbbrev.name("hello", budget: 0), "…", "a non-positive budget still never crashes")
    }

    T.suite("ProjectName") {
        // A synthetic gitRoot probe — no test here touches the real filesystem, and this is the
        // exact fixture from the plan: /a/b/repo and /a/b/repo/site must resolve to the same name.
        let repoGit: (String) -> String? = { path in
            path.hasPrefix("/a/b/repo") ? "/a/b/repo" : nil
        }

        // ── THE BUG: a subdirectory of a repo is the same project ──────────────────────
        T.eq(ProjectName.resolve(cwd: "/a/b/repo/site", windowTitle: "", gitRoot: repoGit), "repo",
             "THE BUG: a subdirectory is the same project")
        T.eq(ProjectName.resolve(cwd: "/a/b/repo", windowTitle: "", gitRoot: repoGit), "repo",
             "and the repo root itself names it the same way")

        // ── the probe is asked ONCE, for cwd itself — see the doc comment on `resolve` ──
        var gitCalls: [String] = []
        let trackingGit: (String) -> String? = { path in
            gitCalls.append(path)
            return path.hasPrefix("/a/b/repo") ? "/a/b/repo" : nil
        }
        _ = ProjectName.resolve(cwd: "/a/b/repo/site", windowTitle: "", gitRoot: trackingGit)
        T.eq(gitCalls, ["/a/b/repo/site"],
             "the probe is asked once, for the cwd itself — not retried against a derived path")

        // ── fallback ladder: git root → cwd leaf → window-title head → nil ─────────────
        T.eq(ProjectName.resolve(cwd: "/x/y/proj", windowTitle: "ignored — title", gitRoot: { _ in nil }),
             "proj", "no git root found — the cwd's own leaf still beats the window title")
        T.eq(ProjectName.resolve(cwd: "/a/b/leaf", windowTitle: "", gitRoot: { _ in "/" }),
             "leaf", "a probe returning bare \"/\" is not a usable project name — the cwd leaf wins instead")
        T.eq(ProjectName.resolve(cwd: nil, windowTitle: "solo — x", gitRoot: { _ in nil }),
             "solo", "no cwd at all — the last resort is the window title's head")
        T.eq(ProjectName.resolve(cwd: "", windowTitle: "solo", gitRoot: { _ in nil }),
             "solo", "an empty cwd is treated exactly like no cwd")
        T.ok(ProjectName.resolve(cwd: nil, windowTitle: "", gitRoot: { _ in nil }) == nil,
             "nothing derived anywhere is nil, never a sentinel string")

        // ── titleHead — the moved-verbatim logic, with the sentinel change ──────────────
        T.eq(ProjectName.titleHead("36.macai — ◑ Chut — caffeinate ◂ claude — 245×76"), "36.macai",
             "the first em-dash segment, same rule TerminalAppAdapter used")
        T.eq(ProjectName.titleHead("solo"), "solo", "no separator — the whole title is the head")
        T.ok(ProjectName.titleHead("") == nil,
             "nothing derived is nil, not the old \"—\" placeholder")

        // ── of(cwd:) — the impure wrapper, nil/empty cwd ────────────────────────────────
        T.ok(ProjectName.of(cwd: nil) == nil, "of(nil) has no cwd and no title to fall back to")
        T.ok(ProjectName.of(cwd: "") == nil, "an empty cwd behaves like nil here too")

        // ── of(cwd:) wired to the REAL git probe, against a real temp repo ──────────────
        let fm = FileManager.default
        let tmp = NSTemporaryDirectory() + "chute-projectname-\(UUID().uuidString)"
        let base = (tmp as NSString).resolvingSymlinksInPath   // /var is a symlink to /private/var
        defer { try? fm.removeItem(atPath: base) }
        try? fm.createDirectory(atPath: base + "/repo/site", withIntermediateDirectories: true)
        try? fm.createDirectory(atPath: base + "/repo/.git", withIntermediateDirectories: true)
        T.eq(ProjectName.of(cwd: base + "/repo/site"), "repo",
             "of() wires the REAL git probe — a subdirectory of a real repo still names the repo")
        T.eq(ProjectName.of(cwd: base + "/repo"), "repo", "and so does the repo root itself")

        // ── the one that stops the two derivations drifting apart again ────────────────
        // A synthetic, nonexistent path — deliberately so this assertion stays machine-independent
        // now that a real git probe sits in ProjectName.of's path (see the plan's note on
        // SignalSuite's own project(cwd:) case for why a real path would not be safe here).
        T.ok(SignalReader.project(cwd: "/a/b/repo/site") == ProjectName.of(cwd: "/a/b/repo/site"),
             "badge and menu cannot disagree")

        // ── MALFORMED cwd — four cases the hook should never write, and one day will ──────
        //
        // The hook writes `$PWD`, which is always absolute and has no trailing slash. Every case
        // below is therefore "the data is wrong"; the question each answers is what a WRONG cwd is
        // allowed to put on screen. The rule is the same one that motivated this whole file: a
        // name Chute cannot stand behind is not printed as though it could be.
        let noGit: (String) -> String? = { _ in nil }

        // A RELATIVE PATH IS NOT EVIDENCE. `leaf(of:)` would happily return "path" here, and the
        // menu would print a confident project name derived from a string Chute cannot resolve to
        // any location on disk. It falls through to the window title instead — which is empty in
        // this test, so: nothing.
        T.ok(ProjectName.resolve(cwd: "relative/path", windowTitle: "", gitRoot: noGit) == nil,
             "a non-absolute cwd is not evidence — it never names a project")
        T.eq(ProjectName.resolve(cwd: "relative/path", windowTitle: "fallback", gitRoot: noGit),
             "fallback", "and it falls through to the title rather than to nothing")

        // AN UNEXPANDED TILDE is a shell that wrote the literal string. Same rule: not a location.
        T.ok(ProjectName.resolve(cwd: "~", windowTitle: "", gitRoot: noGit) == nil,
             "an unexpanded tilde is a string, not a directory")

        // THE ROOT DIRECTORY names no project — `leaf(of: "/")` collapses to nil rather than to
        // "" or "/", both of which would render as a blank or a slash-shaped name on the row.
        T.ok(ProjectName.resolve(cwd: "/", windowTitle: "", gitRoot: noGit) == nil,
             "the root directory names no project")

        // TRAILING SLASHES, one and many. One is stripped; the second used to leave `leaf` looking
        // at "/a/b/" and returning the empty string AFTER the final slash — an Optional("") that is
        // not nil, so every "no project derived" check downstream passes it through as a real name
        // and the row prints a blank where a project should be.
        T.eq(ProjectName.resolve(cwd: "/a/b/repo/", windowTitle: "", gitRoot: noGit), "repo",
             "one trailing slash changes nothing")
        T.eq(ProjectName.resolve(cwd: "/a/b//", windowTitle: "", gitRoot: noGit), "b",
             "and neither does a doubled one — never an empty name")

        // A GIT ROOT reported with a trailing slash gets the same treatment, because the probe is
        // someone else's code and this function must not assume it is tidy.
        T.eq(ProjectName.resolve(cwd: "/a/b/repo/site", windowTitle: "", gitRoot: { _ in "/a/b/repo/" }),
             "repo", "a git root with a trailing slash still names the repo")

        // ── NAMES PASS THROUGH VERBATIM — no slugging, no lowercasing, no cleverness ──────
        T.eq(ProjectName.resolve(cwd: "/a/b/Client — Norse", windowTitle: "", gitRoot: noGit),
             "Client — Norse",
             "an em-dash inside a DIRECTORY is text; only a window title splits on it")
        T.eq(ProjectName.resolve(cwd: "/a/b/💾-backup", windowTitle: "", gitRoot: noGit),
             "💾-backup", "non-ASCII passes through as itself")
    }
}
