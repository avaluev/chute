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

    // ── A WRITTEN NAME CANNOT LEAVE THE FOLDER IT WAS AIMED AT ──────────────────────────────
    //
    // `chute paste-image --name ../../evil.png` wrote outside the target folder until
    // 2026-09-09: `cmdNew` slugified its `--name` and `cmdPasteImage` handed the flag straight
    // through. The guard went into `candidate`, the one function both of them reach, so this
    // tests the chokepoint rather than the two commands.
    T.suite("NameDerive path components") {
        let dir = NSTemporaryDirectory() + "chute-traversal-\(UUID().uuidString)"
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(atPath: dir) }

        func wrote(base: String, ext: String) -> String? {
            try? NameDerive.writeUniquely(dir: dir, base: base, ext: ext, data: Data("x".utf8))
        }

        for (base, ext, label) in [
            ("../../evil", "png", "a relative escape in the name"),
            ("..", "png", "a bare .. as the name"),
            ("/etc/passwd", "txt", "an absolute path in the name"),
            ("shot", "../../evil.png", "an escape hidden in the extension"),
        ] {
            guard let path = wrote(base: base, ext: ext) else {
                T.ok(false, "\(label): writeUniquely threw"); continue
            }
            T.eq((path as NSString).deletingLastPathComponent, dir,
                 "\(label) still lands directly in the target folder")
            // NOT "the path contains no ..": flattening `../../evil` leaves the harmless file
            // name `-..-evil.png`, which is ugly and stays put. The invariant is CONTAINMENT —
            // the bytes landed on disk inside `dir` — so that is what is asserted.
            T.ok(FileManager.default.fileExists(atPath: path),
                 "\(label) actually wrote, inside the folder")
        }

        // The guard must not eat ordinary names, which is the failure mode of reaching for
        // `slugify` here: it lowercases and dashes, and `underscoreName` exists precisely so a
        // file can be called "This_is_the_header.md".
        T.eq((wrote(base: "This_is_the_header", ext: "md") as NSString?)?.lastPathComponent,
             "This_is_the_header.md", "an ordinary underscored name is passed through untouched")
    }
}
