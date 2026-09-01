import Foundation
import ChuteCore

func confirmPromptSuite() {
    T.suite("ConfirmPrompt") {
        // The count in the title is the count of ITEMS, not of lines the sheet happens to show.
        let three = ConfirmPrompt(actionTitle: "Move Junk to Trash", preview: "a.log\nb.log\nc.log\n")
        T.eq(three.itemCount, 3, "blank trailing lines are not items")
        T.eq(three.title, "Move Junk to Trash — 3 item(s)", "the title names the action and the size")
        T.eq(three.body, "a.log\nb.log\nc.log", "a short list is shown whole")

        // A selection can be thousands of files. The sheet must stay dismissable AND must say how
        // much it did not show — a truncated list with no remainder reads as the complete one.
        let many = ConfirmPrompt(actionTitle: "Clean", preview: (1...40).map { "f\($0)" }.joined(separator: "\n"))
        T.eq(many.itemCount, 40, "every item is counted, not just the shown ones")
        T.eq(many.body.split(separator: "\n").count, 16, "15 rows plus the remainder line")
        T.ok(many.body.hasSuffix("… and 25 more"), "the remainder is stated, not implied")
        T.ok(many.title.contains("40 item(s)"), "the title carries the real total, not the shown count")

        // THE ONE THAT MATTERS. An empty dry run rendered an empty sheet, which is a user clicking
        // a destructive button on a list they cannot see.
        let empty = ConfirmPrompt(actionTitle: "Clean", preview: "")
        T.eq(empty.itemCount, 0, "an empty dry run found nothing")
        T.eq(empty.body, "Nothing to change here.", "and says so rather than showing a blank sheet")
        T.eq(ConfirmPrompt(actionTitle: "Clean", preview: "\n \n\n").body, "Nothing to change here.",
             "whitespace-only output is empty too")

        // The dry run's own indentation is the CLI's formatting, not part of the file name.
        T.eq(ConfirmPrompt(actionTitle: "Clean", preview: "   a.log\n\tb.log").body, "a.log\nb.log",
             "rows are trimmed")

        // Boundary: exactly at the limit there is no remainder line to add.
        let exact = ConfirmPrompt(actionTitle: "Clean", preview: (1...15).map { "f\($0)" }.joined(separator: "\n"))
        T.ok(!exact.body.contains("more"), "exactly at the limit, nothing is hidden")
        T.eq(ConfirmPrompt(actionTitle: "Clean", preview: (1...16).map { "f\($0)" }.joined(separator: "\n"))
                .body.hasSuffix("… and 1 more"), true, "one over the limit hides exactly one")
    }
}
