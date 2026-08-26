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
