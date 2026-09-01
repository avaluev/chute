import Foundation
import ChuteCore

// MARK: - FR-04 clipboard → file

func cmdNew(_ a: Args) {
    // --blank makes an empty document. The clipboard is irrelevant, and demanding one would be
    // the difference between "New Markdown File" working and mysteriously refusing.
    let blank = a.has("blank")
    let content = blank ? "" : (a.has("stdin")
        ? String(data: FileHandle.standardInput.readDataToEndOfFile(), encoding: .utf8) ?? ""
        : Clipboard.read())
    if !blank, content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        Out.fail("clipboard is empty — copy something first")
    }
    let dir = FileScan.absolute(a.value("dir", or: FileManager.default.currentDirectoryPath))
    guard FileScan.isDirectory(dir) else { Out.fail("not a directory: \(dir)") }

    let ext = a.optional("ext") ?? (blank ? "md" : LanguageDetect.fileExtension(for: content))
    // --naming underscore keeps the document's own first line: "# My Notes" → "My_Notes.md".
    // The default stays the kebab slug the CLI has always produced.
    let derived = a.value("naming", or: "slug") == "underscore"
        ? NameDerive.underscoreName(from: content)
        : NameDerive.slug(fromMarkdown: content)
    let base = a.optional("name").map { NameDerive.slugify($0) }
        ?? (blank ? "Untitled" : nil)
        ?? derived
        ?? NameDerive.fallbackName()

    let path: String
    do { path = try NameDerive.writeUniquely(dir: dir, base: base, ext: ext,
                                             data: Data(content.utf8)) }
    catch { Out.fail("cannot write in \(dir): \(error.localizedDescription)") }
    Out.line(path)
    Out.info("→ created \((path as NSString).lastPathComponent)"
             + (blank ? "" : " · \(TokenEstimate.badge(TokenEstimate.tokens(in: content)))"))
    // --rename reveals the file AND starts Finder's inline rename, so the name is selected and
    // you can just type. --reveal alone only shows it.
    if a.has("rename") {
        if let problem = FinderReveal.revealAndBeginRename(path) { Out.info("→ \(problem)") }
    } else if a.has("reveal") {
        Shell.launch("open", ["-R", path])
    }
}

// FR-06 markdown → filesystem (`chute unpack`, `MarkdownUnpack.swift`) removed 2026-08-31: the
// ICP is Claude Code / Cursor users, whose agent already writes files to disk — the moment this
// existed for (a browser chat that can only hand back fenced code blocks) never occurs for them.
// See docs/specs/move-5-delete-unpack.md.

// MARK: - FR-11 seed agent rules

func cmdSeed(_ a: Args) {
    let dir = a.paths(defaultToCWD: true)[0]
    guard FileScan.isDirectory(dir) else { Out.fail("not a directory: \(dir)") }
    let project = (dir as NSString).lastPathComponent
    let rules = a.value("rules", or: "claude,cursor,scratchpad").split(separator: ",").map(String.init)
    var written = 0
    var failed = 0
    for rule in rules {
        guard let name = Templates.fileName(for: rule), let body = Templates.body(for: rule, project: project) else {
            Out.info("unknown rule '\(rule)' — known: \(Templates.all.joined(separator: ", "))")
            continue
        }
        let path = (dir as NSString).appendingPathComponent(name)
        if FileManager.default.fileExists(atPath: path) {
            Out.info("kept existing \(name)")   // NFR-08 — never overwrite
            continue
        }
        do { try body.write(toFile: path, atomically: true, encoding: .utf8) }
        catch { Out.info("failed \(name): \(error.localizedDescription)"); failed += 1; continue }
        Out.line("created \(path)")
        written += 1
    }
    Out.info("→ \(written) file(s) seeded")
    // "0 seeded" reads as "nothing to do" — and it was, when every file already existed. When the
    // writes were ATTEMPTED and all of them failed, exit 0 tells a script the opposite of the truth.
    if written == 0 && failed > 0 { Out.fail("no rules could be written (\(failed) failed)") }
}

// MARK: - FR-16 scratchpad anchor

func cmdNote(_ a: Args) {
    let dir = FileScan.absolute(a.value("dir", or: FileManager.default.currentDirectoryPath))
    let text = a.positional.joined(separator: " ")
    guard !text.isEmpty else { Out.fail("usage: chute note \"where I left off\"") }
    let path = (dir as NSString).appendingPathComponent("SCRATCHPAD.md")
    let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd HH:mm"
    let entry = "\n## \(f.string(from: Date()))\n\(text)\n"
    if let handle = FileHandle(forWritingAtPath: path) {
        handle.seekToEndOfFile()
        handle.write(Data(entry.utf8))
        handle.closeFile()
    } else {
        let header = Templates.body(for: "scratchpad", project: (dir as NSString).lastPathComponent) ?? ""
        // A note is the thing you write BECAUSE you are about to lose state — reporting
        // "anchored" over a failed write is the worst possible lie here.
        do { try (header + entry).write(toFile: path, atomically: true, encoding: .utf8) }
        catch { Out.fail("cannot write \(path): \(error.localizedDescription)") }
    }
    Out.line(path)
    Out.info("→ anchored")
}

// MARK: - FR-12 reveal latest artifact

func cmdLatest(_ a: Args) {
    let dir = a.paths(defaultToCWD: true)[0]
    guard FileScan.isDirectory(dir) else { Out.fail("not a directory: \(dir)") }
    var newest: (path: String, date: Date)?
    for p in FileScan.expand([dir], maxFiles: 5000) {
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: p),
              let date = attrs[.modificationDate] as? Date else { continue }
        if newest == nil || date > newest!.date { newest = (p, date) }
    }
    guard let hit = newest else { Out.fail("no files found under \(dir)") }
    Out.line(hit.path)
    if a.has("quicklook") { Shell.launch("qlmanage", ["-p", hit.path]) }
    else { Shell.launch("open", ["-R", hit.path]) }
}

// MARK: - FR-14 clean agent scratch

func cmdClean(_ a: Args) {
    let dir = a.paths(defaultToCWD: true)[0]
    guard FileScan.isDirectory(dir) else { Out.fail("not a directory: \(dir)") }
    // includingJunk: this is the one command that is LOOKING for junk. Without it the walk drops
    // every scratch EXTENSION before `clean` sees it, and only the scratch PREFIXES ever showed up.
    let candidates = FileScan.expand([dir], maxFiles: 5000, includingJunk: true).filter {
        Junk.isAgentScratch(name: ($0 as NSString).lastPathComponent)
    }
    guard !candidates.isEmpty else { Out.info("nothing to clean"); return }

    // NFR-05 — list by default, delete only with --force.
    guard a.has("force") else {
        Out.info("dry run — \(candidates.count) scratch file(s):")
        candidates.forEach { Out.line("  \($0)") }
        Out.info("→ re-run with --force to delete")
        return
    }
    var removed = 0
    for p in candidates where (try? FileManager.default.trashItem(at: URL(fileURLWithPath: p), resultingItemURL: nil)) != nil {
        removed += 1
    }
    Out.info("→ moved \(removed) file(s) to Trash")
}
