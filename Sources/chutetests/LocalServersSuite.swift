import Foundation
import ChuteCore

func localServersSuite() {
    T.suite("LocalServers") {
        // Captured from this machine on 2026-08-27. Real output, not a hand-written idealisation:
        // IPv4/IPv6 duplicate rows, an Apple daemon, an ephemeral port and a bracketed IPv6 address.
        let sample = """
        COMMAND     PID  USER   FD   TYPE             DEVICE SIZE/OFF NODE NAME
        rapportd    600 sxope   14u  IPv4 0x6457fff30d1357d3      0t0  TCP *:64682 (LISTEN)
        ControlCe   678 sxope    5u  IPv4 0x88ef8a2125e52ecf      0t0  TCP *:7000 (LISTEN)
        redis-ser  5360 sxope    6u  IPv4 0xab9abfffcff33eac      0t0  TCP 127.0.0.1:6379 (LISTEN)
        redis-ser  5360 sxope    7u  IPv6 0xbe1b29f4e2ea6e9b      0t0  TCP [::1]:6379 (LISTEN)
        postgres   5375 sxope    7u  IPv6 0x2a60d8935f737de9      0t0  TCP [::1]:5432 (LISTEN)
        postgres   5375 sxope    8u  IPv4 0xb42e82d238eacc9f      0t0  TCP 127.0.0.1:5432 (LISTEN)
        node      33176 sxope   24u  IPv6 0x1111111111111111      0t0  TCP *:3400 (LISTEN)
        """
        let servers = LocalServers.parse(lsof: sample)

        // ─── Killing a port: the tree, not the leaf ──────────────────────
        //
        // Captured from this machine on 2026-08-27 with `ps -axo pid=,ppid=,comm=`,
        // while three real dev servers were up. The shapes that matter are all
        // here: a THREE-deep npm→node→next-server chain (:3477), a TWO-deep
        // npm→next-server chain (:3400), a server whose parent is a SHELL, and
        // an unrelated Chrome process holding a client socket.
        let psSample = """
        1 0 /sbin/launchd
        90549 1 npm exec next dev -p 3477
        90587 90549 /Users/sxope/.../node_modules/.bin/next
        90588 90587 next-server
        33068 1 npm exec next start -p 3400
        33176 33068 node
        42501 900 /Applications/Google Chrome.app/Contents/MacOS/Google Chrome
        900 1 /System/Applications/Utilities/Terminal.app/Contents/MacOS/Terminal
        7001 900 -zsh
        7002 7001 node
        """
        let table = LocalServers.parseProcessTable(psSample)

        T.eq(table[90588]?.command, "next-server", "comm's path tail is the command name")
        T.eq(table[90549]?.command, "npm", "an argument tail is dropped — npm, not `npm exec next dev`")
        T.eq(table[42501]?.command, "Google Chrome",
             "a bundle whose name contains a space is not cut in half")
        // REGRESSION. A macOS path with a space in it — Application Support, Google Drive,
        // iCloud Drive, any app bundle with a two-word name. Cutting at the first space and
        // taking the basename of the remainder gave "Sublime", the climb to the process-tree
        // root stopped early, and Stop It left the supervisor running.
        let spaced = LocalServers.parseProcessTable(
            "4242 1 /Users/me/Google Drive/app/node_modules/.bin/next\n")
        T.eq(spaced[4242]?.command, "next", "a path containing a space still yields the executable")
        T.eq(table[90587]?.ppid, 90549, "the middle of the chain keeps its parent")

        // THE BUG THIS FIXES. lsof hands back 90588 and only 90588; killing it
        // leaves npm alive to respawn the child, which is why "Stop It" read as
        // doing nothing.
        T.eq(LocalServers.killSet(listener: 90588, table: table), [90549, 90587, 90588],
             "the whole npm -> node -> next-server tree dies, not just the leaf lsof returns")
        T.eq(LocalServers.killSet(listener: 33176, table: table), [33068, 33176],
             "a two-deep npm -> node chain climbs to npm")

        // THE GUARD. Climbing to pid 1 would take the user's shell and Terminal
        // with it. The climb stops at the first non-runner ancestor, so the
        // worst case is a subtree that is too small, never a closed window.
        T.eq(LocalServers.killSet(listener: 7002, table: table), [7002],
             "the climb STOPS at a shell — killing a server must never kill the terminal")
        T.ok(!LocalServers.killSet(listener: 90588, table: table).contains(42501),
             "an unrelated Chrome process is never in the kill set")
        T.ok(!LocalServers.killSet(listener: 90588, table: table).contains(1),
             "launchd is never in the kill set")

        // A MULTIPLEXER IS NOT A SUPERVISOR. turbo/concurrently do not respawn a child that
        // exits, so climbing through one buys nothing and takes every sibling: "Stop It" on
        // :3001 in a Turborepo killed :3000 and :3002 too. The climb stops below them.
        let turbo: [Int: (ppid: Int, command: String)] = [
            100: (ppid: 1, command: "zsh"), 200: (ppid: 100, command: "turbo"),
            300: (ppid: 200, command: "node"), 301: (ppid: 300, command: "next-server"),
            400: (ppid: 200, command: "node"), 401: (ppid: 400, command: "next-server"),
        ]
        T.eq(LocalServers.killSet(listener: 301, table: turbo), [300, 301],
             "stopping one app under turbo takes its own node, not turbo and the sibling app")
        T.no(LocalServers.killSet(listener: 301, table: turbo).contains(401), "the sibling listener survives")

        // A self-parenting or cyclic table must terminate rather than hang.
        T.eq(LocalServers.killSet(listener: 5, table: [5: (ppid: 5, command: "node")]), [5],
             "a self-parenting pid terminates the climb instead of looping")

        // ─── launchd-supervised services: bootout, never kill ────────────
        //
        // THE OTHER HALF OF "Stop It does nothing". postgres, redis and ollama
        // from `brew services` are launchd agents with KeepAlive=true: launchd
        // respawns them the instant the signal lands, so kill -TERM *and*
        // kill -9 both read as no-ops from the menu. Captured from this machine
        // on 2026-08-27: all three had ppid 1 and a homebrew.mxcl.* label.
        let launchctlSample = "PID\tStatus\tLabel\n"
            + "14471\t0\thomebrew.mxcl.postgresql@16\n"
            + "11867\t0\thomebrew.mxcl.redis\n"
            + "-\t0\tcom.apple.mbfloagent\n"
            + "47743\t-9\thomebrew.mxcl.ollama\n"
            + "garbage line\n"
        let jobs = LocalServers.parseLaunchdJobs(launchctlSample)
        T.eq(jobs[14471], "homebrew.mxcl.postgresql@16", "a live launchd job maps pid to label")
        T.eq(jobs[47743], "homebrew.mxcl.ollama", "a negative Status column is still a live job")
        T.eq(jobs.count, 3, "the header, dead jobs (PID '-') and garbage are all skipped")

        // postgres: the postmaster (14471, ppid 1) listens; workers are its children.
        let brewTable = LocalServers.parseProcessTable("""
        1 0 /sbin/launchd
        14471 1 /opt/homebrew/opt/postgresql@16/bin/postgres
        14475 14471 postgres
        7001 1 npm exec next dev
        7002 7001 node
        """)
        let plan = LocalServers.killPlan(listeners: [14471, 7002], jobs: jobs, table: brewTable)
        T.eq(plan.bootout.map(\.pid), [14471], "a launchd-owned listener is booted out, not signalled")
        T.eq(plan.bootout.first?.label, "homebrew.mxcl.postgresql@16", "bootout is addressed by label")
        T.eq(plan.signal, [7001, 7002], "a free process still gets its runner tree signalled")
        T.ok(!plan.signal.contains(14471) && !plan.signal.contains(14475),
             "nothing under a launchd job is ever signalled — launchd would just respawn it")

        // A launchd job that RUNS a runner: the job is an ancestor of the
        // listener, not the listener itself. The whole subtree goes to bootout.
        let supervised = LocalServers.parseProcessTable("""
        1 0 /sbin/launchd
        500 1 node
        501 500 node
        """)
        let plan2 = LocalServers.killPlan(listeners: [501], jobs: [500: "dev.example.daemon"],
                                          table: supervised)
        T.eq(plan2.bootout.map(\.label), ["dev.example.daemon"],
             "a launchd job anywhere in the kill tree turns the whole stop into a bootout")
        T.eq(plan2.signal, [], "and leaves nothing to signal")


        T.eq(servers.map(\.port), [3400, 5432, 6379], "sorted by port, one row per server")
        T.ok(!servers.contains { $0.command == "rapportd" }, "an ephemeral macOS listener is not a server")
        T.ok(!servers.contains { $0.command == "ControlCe" }, "AirPlay's port 7000 is not your dev server")
        T.eq(servers.first(where: { $0.port == 6379 })?.pid, 5360, "the IPv4 and IPv6 rows are one server")
        T.eq(servers.first(where: { $0.port == 6379 })?.loopbackOnly, true, "loopback stays loopback")
        T.eq(servers.first(where: { $0.port == 3400 })?.loopbackOnly, false,
             "a server on every interface is reported as reachable from the network")
        T.eq(servers.first(where: { $0.port == 5432 })?.kind, "postgres", "commands are named in words")
        T.eq(servers.first(where: { $0.port == 6379 })?.kind, "redis", "even when lsof truncates them")
        T.eq(LocalServer(port: 3000, command: "wibble", pid: 1, loopbackOnly: true).kind, "wibble",
             "an unknown command keeps its own name rather than being guessed at")
        T.eq(LocalServers.parse(lsof: "").count, 0, "no output is no servers, not a crash")
        T.eq(LocalServers.parse(lsof: "garbage\nmore garbage").count, 0, "garbage is skipped, never parsed")

        // Working directories: what turns ":3400 · node" into ":3400 · node · sntz_mockups".
        let dirs = LocalServers.parseWorkingDirs("""
        p33176
        fcwd
        n/Users/sxope/Documents/5.STNZ.AI/sntz_mockups
        p5371
        fcwd
        n/private/var/folders/x
        p600
        fcwd
        n/
        """)
        T.eq(dirs[33176], "/Users/sxope/Documents/5.STNZ.AI/sntz_mockups", "a real project directory is kept")
        T.ok(dirs[5371] == nil, "a daemon running from /private/var has no project")
        T.ok(dirs[600] == nil, "and neither does one running from /")

        T.eq(LocalServer(port: 3000, command: "node", pid: 1, loopbackOnly: true, project: "studylock").label,
             ":3000 · node · studylock", "the menu line reads as one thought")
        T.eq(LocalServer(port: 3000, command: "node", pid: 1, loopbackOnly: true).label,
             ":3000 · node", "and drops the project when there is none")
        T.eq(LocalServer(port: 8080, command: "node", pid: 1, loopbackOnly: true).url,
             "http://localhost:8080", "the URL is the thing you paste into a browser")

        // ─── Copy Server List: one paste that tells an agent everything ──
        let listing = LocalServers.report([
            LocalServer(port: 3220, command: "node", pid: 445, loopbackOnly: false, project: "studylock"),
            LocalServer(port: 5432, command: "postgres", pid: 14471, loopbackOnly: true),
        ])
        let lines = listing.split(separator: "\n").map(String.init)
        T.eq(lines.count, 2, "one line per server, nothing else — paste-ready")
        T.eq(lines[0], "port 3220 · node · project studylock · pid 445 · reachable from your network · http://localhost:3220",
             "a line carries everything an agent needs to say what it is")
        T.eq(lines[1], "port 5432 · postgres · pid 14471 · this Mac only · http://localhost:5432",
             "no project is no filler text")
        T.eq(LocalServers.report([]), "", "an empty list copies as nothing, not a header")
    }
}
