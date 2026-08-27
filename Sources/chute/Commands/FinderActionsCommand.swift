import Foundation
import ChuteCore

/// `chute finder-actions [--json]` — the Finder menu's own action table, printed.
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
                "argv": ChuteActions.argv(action, dir: dir, files: files),
            ]
        }
        let data = try? JSONSerialization.data(withJSONObject: payload,
                                               options: [.prettyPrinted, .sortedKeys])
        Out.line(String(decoding: data ?? Data("[]".utf8), as: UTF8.self))
        return
    }

    for action in ChuteActions.all {
        Out.line("\(action.id.padding(toLength: 20, withPad: " ", startingAt: 0)) \(action.title(count: files.count))")
        Out.line("                     \(action.detail)")
    }
}
