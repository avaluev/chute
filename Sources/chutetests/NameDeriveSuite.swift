import Foundation
import ChuteCore

func nameDeriveSuite() {
    T.suite("NameDerive underscore naming") {
        // The rule, stated by the founder: take the first line of text, drop the heading marks,
        // spaces become underscores. Predictable enough to guess before you click.
        T.eq(NameDerive.underscoreName(from: "# This is thd header\n\nbody"),
             "This_is_thd_header", "a heading becomes the file name verbatim, spaces underscored")
        T.eq(NameDerive.underscoreName(from: "Plain first line\nsecond"),
             "Plain_first_line", "no heading marks needed")
        T.eq(NameDerive.underscoreName(from: "\n\n   \n### Third try"),
             "Third_try", "blank lines are skipped to the first real one")
        T.eq(NameDerive.underscoreName(from: "Report: Q3/Q4 <draft>"),
             "Report_Q3Q4_draft", "characters a filesystem argues about are dropped")
        T.eq(NameDerive.underscoreName(from: "Case Is Preserved EXACTLY"),
             "Case_Is_Preserved_EXACTLY", "no lowercasing — it is the user's title, not a slug")
        T.eq(NameDerive.underscoreName(from: String(repeating: "a", count: 200))?.count, 60,
             "a runaway first line is cropped")
        T.eq(NameDerive.underscoreName(from: "Trailing spaces   "),
             "Trailing_spaces", "no trailing underscore is left behind")
        T.ok(NameDerive.underscoreName(from: "") == nil, "nothing to name is nil, not an empty file name")
        T.ok(NameDerive.underscoreName(from: "###") == nil, "and neither is a bare heading mark")
    }
}
