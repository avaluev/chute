import Foundation

/// A project's colour must be identical every launch, so it is derived from the path,
/// never assigned in discovery order. Claude Code's own `/color` is not persisted to
/// disk anywhere, so Chute owns this rather than depending on an internal format.
public enum SessionColor {
    /// Twelve hues that stay distinguishable against both light and dark menu backgrounds.
    public static let palette: [String] = [
        "#E06C75", "#E5934A", "#E5C07B", "#98C379",
        "#56B6C2", "#61AFEF", "#8C7AE6", "#C678DD",
        "#D19A66", "#4DB6AC", "#7E9CD8", "#DE8F78",
    ]

    /// FNV-1a, 32-bit. Chosen because it is short, stable across platforms and versions,
    /// and has no dependency — unlike Swift's `Hasher`, which is seeded per process.
    public static func index(forProject path: String) -> Int {
        var hash: UInt32 = 2_166_136_261
        for byte in path.utf8 {
            hash ^= UInt32(byte)
            hash = hash &* 16_777_619
        }
        return Int(hash % UInt32(palette.count))
    }

    public static func hex(forProject path: String) -> String {
        palette[index(forProject: path)]
    }

    /// Parse `#RRGGBB` (or a bare `RRGGBB`) into components in 0...1. Nil for anything else.
    ///
    /// The caller draws grey when this returns nil, so a mis-typed palette entry is VISIBLE
    /// rather than black. `UInt32(_:radix:)` alone is not enough: it accepts a leading sign, so
    /// "+ABCDE" is six characters and parses happily to 0xABCDE. Hence the digit check.
    public static func rgb(hex: String) -> (red: Double, green: Double, blue: Double)? {
        var s = hex
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6, s.allSatisfy(\.isHexDigit), let v = UInt32(s, radix: 16) else { return nil }
        return (Double((v >> 16) & 0xFF) / 255,
                Double((v >> 8) & 0xFF) / 255,
                Double(v & 0xFF) / 255)
    }
}
