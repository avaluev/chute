import Foundation

/// Expands a Finder selection into readable text files.
public enum FileScan {
    public static let fm = FileManager.default

    public static func isDirectory(_ path: String) -> Bool {
        var isDir: ObjCBool = false
        return fm.fileExists(atPath: path, isDirectory: &isDir) && isDir.boolValue
    }

    /// Directories expand recursively, skipping junk. Files pass through.
    /// - Parameter includingJunk: keep the files a walk normally drops. Off for everything that
    ///   builds context — junk in a prompt is wasted tokens. On for `clean`, whose whole job is to
    ///   FIND that junk: filtering it out here made `clean` blind to every `.log`, `.tmp`, `.bak`,
    ///   `.swp`, `.orig` and `.rej` on disk, which is most of what it advertises removing. It still
    ///   only ever trashes what `Junk.isAgentScratch` claims, so `.env` and `.DS_Store` become
    ///   visible here and are then rejected there.
    public static func expand(_ paths: [String], maxFiles: Int = 500,
                              includingJunk: Bool = false) -> [String] {
        var out: [String] = []
        for p in paths {
            let abs = absolute(p)
            guard fm.fileExists(atPath: abs) else { continue }
            if isDirectory(abs) {
                out.append(contentsOf: walk(abs, limit: maxFiles - out.count,
                                            includingJunk: includingJunk))
            } else {
                out.append(abs)
            }
            if out.count >= maxFiles { break }
        }
        return Array(out.prefix(maxFiles))
    }

    static func walk(_ dir: String, limit: Int, includingJunk: Bool = false) -> [String] {
        guard limit > 0 else { return [] }
        var out: [String] = []
        guard let e = fm.enumerator(atPath: dir) else { return [] }
        while let rel = e.nextObject() as? String {
            let name = (rel as NSString).lastPathComponent
            let full = (dir as NSString).appendingPathComponent(rel)
            if isDirectory(full) {
                if Junk.directories.contains(name) { e.skipDescendants() }
                continue
            }
            if !includingJunk, Junk.isJunk(name: name, isDirectory: false) { continue }
            out.append(full)
            if out.count >= limit { break }
        }
        return out
    }

    public static func absolute(_ p: String) -> String {
        let expanded = (p as NSString).expandingTildeInPath
        if expanded.hasPrefix("/") { return expanded }
        return (fm.currentDirectoryPath as NSString).appendingPathComponent(expanded)
    }

    /// NFR-12 — binaries are skipped, never corrupted into the context.
    public static func readText(_ path: String) -> String? {
        guard let data = fm.contents(atPath: path) else { return nil }
        if data.prefix(8192).contains(0) { return nil }          // NUL byte ⇒ binary
        return String(data: data, encoding: .utf8)
    }

    public static func bundleFiles(_ paths: [String]) -> (files: [BundleFile], skipped: [String]) {
        var files: [BundleFile] = []
        var skipped: [String] = []
        for p in paths {
            if let text = readText(p) { files.append(BundleFile(path: p, content: text)) }
            else { skipped.append(p) }
        }
        return (files, skipped)
    }
}
