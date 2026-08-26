import Foundation

/// Directories and files no agent ever wants in its context, and no human wants in a tree.
public enum Junk {
    public static let directories: Set<String> = [
        ".git", "node_modules", ".build", ".swiftpm", "dist", "build", ".next", ".nuxt",
        "__pycache__", ".venv", "venv", "target", "vendor", ".turbo", ".cache",
        ".pytest_cache", ".mypy_cache", "coverage", ".gradle", "DerivedData", ".idea", ".vscode",
    ]

    public static let files: Set<String> = [".DS_Store", "Thumbs.db", ".env"]

    public static let scratchPatterns = [
        "temp_", "tmp_", "test_debug", "scratch", "untitled", "Untitled",
    ]

    public static let scratchExtensions: Set<String> = ["log", "tmp", "swp", "orig", "rej", "bak"]

    public static func isJunk(name: String, isDirectory: Bool) -> Bool {
        if isDirectory { return directories.contains(name) }
        if files.contains(name) { return true }
        if scratchExtensions.contains((name as NSString).pathExtension) { return true }
        return false
    }

    /// FR-14 — throwaway files an agent left behind. Deliberately conservative.
    public static func isAgentScratch(name: String) -> Bool {
        if scratchExtensions.contains((name as NSString).pathExtension) { return true }
        return scratchPatterns.contains { name.hasPrefix($0) }
    }
}
