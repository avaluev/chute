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

    /// The one place a path becomes absolute — so it is the one place to make it PRESENTABLE.
    ///
    /// `chute clean .` printed `/Users/me/proj/./debug.log`, and `seed`, `note`, `latest` and
    /// `unpack` all did the same: `appendingPathComponent(".")` keeps the dot, and every join
    /// after it carries the `./` into the output. On a tool whose entire product is printing
    /// paths for someone to paste, that is the wrong detail to leave lying around.
    /// DOT COMPONENTS ONLY — deliberately not `standardizingPath`, which also RESOLVES SYMLINKS.
    /// That looked like the tidy stdlib answer and quietly broke `bundle`: it renders each file
    /// relative to the working directory, `/var` is a symlink to `/private/var`, and resolving
    /// one side and not the other left no shared prefix, so every path in a bundle collapsed to
    /// its bare filename. Caught by `smoke.sh` step 2 ("md fence"). The `.` is the whole
    /// complaint; nothing here needs a symlink resolved.
    public static func absolute(_ p: String) -> String {
        let expanded = (p as NSString).expandingTildeInPath
        let joined = expanded.hasPrefix("/")
            ? expanded
            : (fm.currentDirectoryPath as NSString).appendingPathComponent(expanded)
        let flattened = joined.replacingOccurrences(of: "/./", with: "/")
        return flattened.hasSuffix("/.") ? String(flattened.dropLast(2)) : flattened
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
