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

        // A self-parenting or cyclic table must terminate rather than hang.
        T.eq(LocalServers.killSet(listener: 5, table: [5: (ppid: 5, command: "node")]), [5],
             "a self-parenting pid terminates the climb instead of looping")


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
    }
}
