import Foundation
import ChuteCore

/// `chute finder-actions [--json] [--menu] [--confirm]` — the Finder menu's own action table.
///
/// It exists so the end-to-end suite runs exactly what the menu runs: the test reads this list,
/// substitutes a fixture directory and files, and executes every command for real. Without it the
/// test would need a second copy of the table, and a second copy is how the menu drifted into
/// offering actions that could not work.
func cmdFinderActions(_ a: Args) {
    let dir = a.value("dir", or: "{dir}")
    let files = a.positional.isEmpty ? ["{files}"] : a.positional

    if a.has("json") {
        let payload = ChuteActions.all.map { action -> [String: Any] in
            [
                "id": action.id,
                "title": action.title(count: files.count),
                "detail": action.detail,
                "scope": action.scope.rawValue,
                "foldersOnly": action.foldersOnly,
                "parentTitle": action.parentTitle ?? "",
                "confirmButton": action.confirmButton ?? "",
                "argv": ChuteActions.argv(action, dir: dir, files: files),
            ]
        }
        let data = try? JSONSerialization.data(withJSONObject: payload,
                                               options: [.prettyPrinted, .sortedKeys])
        Out.line(String(decoding: data ?? Data("[]".utf8), as: UTF8.self))
        return
    }

    // --menu draws the tree as Finder will draw it. The actions become a few rows, and the
    // only honest way to judge eight rows is to look at them — so this prints what a right-click
    // will show without needing a right-click, a build, or a human at the machine.
    if a.has("menu") {
        Out.line("What a right-click adds to Finder's menu:\n")
        for row in ChuteActions.rows() {
            if row.children.isEmpty {
                Out.line("  \(row.title)")
            } else {
                Out.line("  \(row.title)  ▸")
                for id in row.children {
                    guard let child = ChuteActions.find(id) else { continue }
                    Out.line("        \(child.plainTitle)")
                }
            }
        }
        let rows = ChuteActions.rows()
        Out.info("\n→ \(ChuteActions.all.count) actions, \(rows.count) rows")
        let asks = ChuteActions.all.filter(\.isDestructive).map(\.plainTitle)
        if !asks.isEmpty { Out.info("→ shows you the list first: \(asks.joined(separator: ", "))") }
        return
    }

    for action in ChuteActions.all {
        Out.line("\(action.id.padding(toLength: 20, withPad: " ", startingAt: 0)) \(action.title(count: files.count))")
        Out.line("                     \(action.detail)")
    }
}
