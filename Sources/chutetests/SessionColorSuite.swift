import Foundation
import ChuteCore

func sessionColorSuite() {
    T.suite("SessionColor") {
        T.eq(SessionColor.palette.count, 12, "twelve colours")
        T.ok(SessionColor.palette.allSatisfy { $0.hasPrefix("#") && $0.count == 7 },
             "every entry is a 7-char hex string")

        let a = SessionColor.hex(forProject: "/Users/sxope/Documents/2026/Development/37.chute")
        let b = SessionColor.hex(forProject: "/Users/sxope/Documents/2026/Development/37.chute")
        T.eq(a, b, "same project always gets the same colour")

        let i = SessionColor.index(forProject: "/any/path")
        T.ok(i >= 0 && i < 12, "index stays inside the palette")

        T.eq(SessionColor.index(forProject: ""), SessionColor.index(forProject: ""),
             "empty path is stable, not a crash")

        // The founder's five real projects must not collide into one colour.
        let projects = ["/Users/sxope/Documents/2026/Development/37.chute",
                        "/Users/sxope/Documents/2026/Development/31.Chrome/studylock",
                        "/Users/sxope/Documents/2026/Development/5.STNZ_AI/sntz_mockups",
                        "/Users/sxope/Documents/2026/Development/docs",
                        "/Users/sxope/Documents/2026/Development/BigDeal"]
        let distinct = Set(projects.map { SessionColor.index(forProject: $0) })
        T.ok(distinct.count >= 4, "at most one collision across five real projects")

        // Pin the algorithm itself. FNV-1a is load-bearing: if the hash changes, every user's
        // project colours repaint on upgrade. These two values were computed from the reference
        // implementation; changing them must be a deliberate act, not an accident.
        T.eq(SessionColor.index(forProject: "/Users/sxope/Documents/2026/Development/37.chute"), 8,
             "FNV-1a index is pinned for a known path")
        T.eq(SessionColor.index(forProject: "/Users/sxope/Documents/2026/Development/31.Chrome/studylock"), 6,
             "FNV-1a index is pinned for a second known path")
    }
}
