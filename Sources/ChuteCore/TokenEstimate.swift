import Foundation

/// FR-03 — cheap token estimate so a builder knows before pasting whether it fits the window.
/// ponytail: chars/4 heuristic, not a real BPE tokenizer. Accurate to ~±15% on code and prose,
/// which is all a "will this fit?" decision needs. Swap in a real tokenizer only if users complain.
public enum TokenEstimate {
    /// UTF-8 BYTES, not `text.count`. Two reasons, and the second is the one that matters:
    ///
    ///   · `String.count` counts GRAPHEME CLUSTERS, which means walking the whole string doing
    ///     Unicode grapheme breaking. Measured 2026-09-01 on 336 KB of Swift source: `chute
    ///     tokens` spent 188 ms, most of it here. `utf8.count` is a byte count.
    ///   · A BPE tokenizer operates on bytes. An emoji is ONE grapheme and four bytes, and the
    ///     model is charged for the four — so the byte count is also the more honest estimate,
    ///     not merely the faster one.
    public static func tokens(in text: String) -> Int {
        let n = text.utf8.count
        return n == 0 ? 0 : (n + 3) / 4
    }

    public static func tokens(inFiles contents: [String]) -> Int {
        contents.reduce(0) { $0 + tokens(in: $1) }
    }

    public static func badge(_ n: Int) -> String {
        n >= 1000 ? "~\(n / 1000)k tokens" : "~\(n) tokens"
    }
}
