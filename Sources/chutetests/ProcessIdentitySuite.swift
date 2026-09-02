import Foundation
import ChuteCore

func processIdentitySuite() {
    T.suite("ProcessIdentity") {
        // ── executablePath: real, live process, no privilege needed ────────────────────────
        let me = ProcessInfo.processInfo.processIdentifier
        let myPath = ProcessIdentity.executablePath(me)
        T.ok(myPath != nil, "our own executable path resolves with no root and no entitlement")
        T.ok(myPath?.hasPrefix("/") == true, "and it is an absolute path: \(myPath ?? "nil")")

        T.eq(ProcessIdentity.executablePath(999_999), nil,
             "a pid that does not exist refuses rather than fabricates a path")
        // MEASURED (see ProcessIdentity.swift): proc_pidpath crosses the ownership boundary that
        // proc_pid_rusage does not — verified directly, `sysctl(KERN_PROCARGS2, pid: 1)` returns
        // EINVAL for this non-root user while `proc_pidpath(1, …)` succeeds. So root's launchd
        // resolves fine here; the boundary this feature actually has to respect is on argv.
        T.eq(ProcessIdentity.executablePath(1), "/sbin/launchd",
             "the executable path crosses the ownership boundary that argv does not")

        // ── arguments: real, live process, and the cache actually works ────────────────────
        let myArgs = ProcessIdentity.arguments(me)
        T.ok(myArgs != nil, "our own argv is readable")
        T.ok((myArgs?.isEmpty == false), "and it is not empty — argv[0] is always something")

        T.eq(ProcessIdentity.arguments(999_999), nil,
             "argv for a pid that does not exist is nil, not an empty array")
        T.eq(ProcessIdentity.arguments(1), nil,
             "launchd is root's; unlike the path, argv IS refused for a process we do not own")

        // Read it twice; the second read must be the identical cached array, not a re-parse
        // that happens to agree — argv cannot change for the life of a process, so paying the
        // sysctl cost twice would be pure waste.
        let again = ProcessIdentity.arguments(me)
        T.eq(again, myArgs, "a cached read returns the exact same argv the live syscall did")

        // PID REUSE. A success was cached forever by pid number, so a new browser at a recycled
        // pid was named after a dead one's profile. The cache is keyed on the process's start
        // time; an entry planted under our pid with a different start is a different process.
        ProcessIdentity.plantCachedArgv(["ghost", "--user-data-dir=/dead"], pid: me, start: 1)
        T.eq(ProcessIdentity.arguments(me), myArgs,
             "a cache entry from a previous process at the same pid is never served")

        // ── userDataDir: PURE, no process, every shape it has to survive ───────────────────
        T.eq(ProcessIdentity.userDataDir(argv: ["chrome", "--user-data-dir=/Users/x/profile-a"]),
             "/Users/x/profile-a", "the '--flag=value' form, one token")
        T.eq(ProcessIdentity.userDataDir(argv: ["chrome", "--user-data-dir", "/Users/x/profile-b"]),
             "/Users/x/profile-b", "the '--flag value' form, two space-separated tokens")
        T.eq(ProcessIdentity.userDataDir(argv: ["chrome", "--headless", "--no-sandbox"]), nil,
             "a browser launched without the flag is honestly nil, not a fabricated path")
        T.eq(ProcessIdentity.userDataDir(argv: []), nil, "an empty argv is nil")
        T.eq(ProcessIdentity.userDataDir(argv: ["chrome", "--user-data-dir="]), nil,
             "an '=' with nothing after it is treated as absent, not as an empty-string profile")
        T.eq(ProcessIdentity.userDataDir(argv: ["chrome", "--user-data-dir"]), nil,
             "the flag as the LAST token, with no value following, is absent — not an out-of-bounds read")
        T.eq(ProcessIdentity.userDataDir(argv: ["chrome", "--user-data-dir", ""]), nil,
             "the two-token form with an empty value is also treated as absent")
        T.eq(ProcessIdentity.userDataDir(
                argv: ["chrome", "--user-data-dir=/Users/x/Library/Caches/ms-playwright/mcp-chrome-9ebcc11"]),
             "/Users/x/Library/Caches/ms-playwright/mcp-chrome-9ebcc11",
             "a realistic Playwright profile path survives whole")
        T.eq(ProcessIdentity.userDataDir(
                argv: ["chrome", "--profile-directory=Default", "--user-data-dir=/a/b", "--flag"]),
             "/a/b", "the flag is found regardless of where it sits among the other switches")

        // ── label: composed from injected closures, NO live process at all ─────────────────
        //
        // A three-process fixture that mirrors a real Chromium tree: the browser (100) carries
        // --user-data-dir; a renderer (101) is its direct child and carries no profile flag at
        // all — renderers are per SITE, never per profile, which is the whole reason a helper
        // needs to walk up to find the flag in the first place; a GPU helper (102) is a
        // grandchild, two hops from the flag.
        let ppid: [Int32: Int32] = [100: 50, 101: 100, 102: 101]
        let argv: [Int32: [String]] = [
            100: ["chrome", "--user-data-dir=/Users/x/Library/Caches/ms-playwright/mcp-chrome-9ebcc11"],
            101: ["chrome", "--type=renderer", "--enable-crashpad"],
            102: ["chrome", "--type=gpu-process"],
        ]
        let path: [Int32: String] = [
            100: "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
            101: "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome Helper (Renderer)",
            102: "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome Helper (GPU)",
        ]
        func labelFixture(_ pid: Int32) -> String? {
            ProcessIdentity.label(forPID: pid,
                                  ppidOf: { ppid[$0] },
                                  argvOf: { argv[$0] },
                                  pathOf: { path[$0] })
        }

        T.eq(labelFixture(100), "Google Chrome (mcp-chrome-9ebcc11)",
             "the browser process itself is labelled straight from its own argv")
        T.eq(labelFixture(101), "Google Chrome (mcp-chrome-9ebcc11)",
             "a renderer with no profile flag of its own is labelled by walking UP to its browser")
        T.eq(labelFixture(102), "Google Chrome (mcp-chrome-9ebcc11)",
             "and so is a GPU helper two hops away, one further than the renderer")

        // A directory PATH becomes its BASENAME — that is the identifying half a person reads,
        // not the full Caches path leading up to it.
        let deepDir: [Int32: [String]] = [200: ["chrome", "--user-data-dir=/a/b/c/mcp-chrome-deadbeef/"]]
        T.eq(ProcessIdentity.label(forPID: 200, ppidOf: { _ in nil }, argvOf: { deepDir[$0] },
                                   pathOf: { _ in "/opt/chrome" }),
             "chrome (mcp-chrome-deadbeef)",
             "the label is the directory's basename, a trailing slash included, not the whole path")

        // No ancestor ever carries the flag — a plain browser session with no anti-detect
        // wrapper and no Playwright profile, or a process tree that has nothing to do with
        // Chrome at all. This must come back nil, not a guess.
        let plain: [Int32: Int32] = [300: 1]
        T.eq(ProcessIdentity.label(forPID: 300, ppidOf: { plain[$0] }, argvOf: { _ in ["node"] },
                                   pathOf: { _ in "/usr/local/bin/node" }),
             nil, "when nothing up the chain carries --user-data-dir, the answer is honestly nil")

        // A process the caller could not read argv OR ppid for at all (both closures nil) — the
        // most common real failure, another user's process refusing proc_pidpath/sysctl.
        T.eq(ProcessIdentity.label(forPID: 400, ppidOf: { _ in nil }, argvOf: { _ in nil },
                                   pathOf: { _ in nil }),
             nil, "a process we cannot read anything about is refused, not guessed at")

        // Found the flag, but the executable path for THAT process was unreadable — still worth
        // reporting the profile alone rather than throwing the whole answer away.
        let noPath: [Int32: [String]] = [500: ["chrome", "--user-data-dir=/x/only-the-profile"]]
        T.eq(ProcessIdentity.label(forPID: 500, ppidOf: { _ in nil }, argvOf: { noPath[$0] },
                                   pathOf: { _ in nil }),
             "only-the-profile",
             "when the program name is unreadable, the profile basename alone is still returned")

        // THE WALK MUST TERMINATE. A cyclic ppid table (or a self-parenting pid) must not hang
        // the menu — mirrors the cycle guard proved for SystemVitals.attribute.
        let cyclic: [Int32: Int32] = [600: 601, 601: 600]
        T.eq(ProcessIdentity.label(forPID: 600, ppidOf: { cyclic[$0] }, argvOf: { _ in nil },
                                   pathOf: { _ in nil }),
             nil, "a cyclic ppid chain terminates instead of looping forever")
        let selfParent: [Int32: Int32] = [700: 700]
        T.eq(ProcessIdentity.label(forPID: 700, ppidOf: { selfParent[$0] }, argvOf: { _ in nil },
                                   pathOf: { _ in nil }),
             nil, "a self-parenting pid ends the climb on the first step")

        // THE HOP LIMIT. A long, entirely unrelated ancestor chain (no cycle at all) must not be
        // walked all the way to pid 1 looking for a flag that was never going to be there.
        var longChain: [Int32: Int32] = [:]
        for i in Int32(1000)...Int32(1100) { longChain[i] = i + 1 }
        T.eq(ProcessIdentity.label(forPID: 1000, ppidOf: { longChain[$0] }, argvOf: { _ in nil },
                                   pathOf: { _ in nil }),
             nil, "an unrelated 100-hop ancestor chain is abandoned, not walked to the root")
    }
}
