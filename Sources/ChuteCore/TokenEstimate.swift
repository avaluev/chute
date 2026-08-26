import Foundation

/// FR-03 — cheap token estimate so a builder knows before pasting whether it fits the window.
/// ponytail: chars/4 heuristic, not a real BPE tokenizer. Accurate to ~±15% on code and prose,
/// which is all a "will this fit?" decision needs. Swap in a real tokenizer only if users complain.
public enum TokenEstimate {
    public static func tokens(in text: String) -> Int {
        let n = text.count
        return n == 0 ? 0 : (n + 3) / 4
    }

    public static func tokens(inFiles contents: [String]) -> Int {
        contents.reduce(0) { $0 + tokens(in: $1) }
    }

    public static func badge(_ n: Int) -> String {
        n >= 1000 ? "~\(n / 1000)k tokens" : "~\(n) tokens"
    }
}
