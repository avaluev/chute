import AppKit

/// `chute gist` — the words, not the punctuation.
///
/// The About and General tabs are written in the same source the marketing sweep reads, and that
/// source marks a command with markdown backticks. Nothing ever stripped them, so the shipped
/// window read:
///
///     One command uploads, and only when you run it. `chute gist` shells out to your own `gh`…
///
/// with the backticks drawn as literal characters — stray punctuation in a native macOS window,
/// four times in two tabs. It looked like a rendering fault, which is a bad first impression for
/// a paragraph whose entire job is to be believed.
///
/// The fix is presentational and touches NO copy. `docs/FACT-SHEET.md` forbids specific
/// sentences and a deploy gate sweeps for them, so the STRINGS in `AboutText` must stay exactly
/// as they are; only their rendering changes. A backticked span becomes a monospaced run in the
/// same size, which is what the backtick was always asking for.
///
/// It lives in ChuteCore rather than in the window because it is a parser — it has a wrong
/// answer for unmatched ticks, empty spans and adjacent pairs — and `Sources/ChuteApp/` is a
/// target no test can link. That is the same rule `StatusMenu` and `SessionDot` follow, and both
/// of those moved here after shipping a bug nothing could see.
public enum InlineCode {
    /// Split on backticks: even-numbered segments are prose, odd-numbered are code.
    ///
    /// An UNMATCHED trailing tick leaves an odd segment count, and its final segment is prose
    /// that was never closed. Rendering that as code would silently restyle the rest of the
    /// paragraph, so it stays prose and the tick is simply dropped — a typo in the copy must
    /// never be able to change how the rest of a sentence looks.
    public static func segments(_ s: String) -> [(text: String, isCode: Bool)] {
        let parts = s.components(separatedBy: "`")
        // n backticks produce n+1 segments, so ALL ticks are matched exactly when the segment
        // count is ODD. An even count means one tick is unclosed, and the final segment is the
        // prose it opened — excluded here so it renders as prose.
        let lastCodeIndex = parts.count % 2 == 1 ? parts.count : parts.count - 1
        return parts.enumerated().compactMap { i, text in
            text.isEmpty ? nil : (text, i % 2 == 1 && i < lastCodeIndex)
        }
    }

    public static func attributed(_ s: String, font: NSFont, color: NSColor) -> NSAttributedString {
        let out = NSMutableAttributedString()
        // Same point size, so the line height does not change and a paragraph with a command in
        // it sits on the same baseline grid as one without.
        let code = NSFont.monospacedSystemFont(ofSize: font.pointSize, weight: .regular)
        for part in segments(s) {
            out.append(NSAttributedString(string: part.text, attributes: [
                .font: part.isCode ? code : font,
                .foregroundColor: color,
            ]))
        }
        return out
    }
}
