import Foundation
import ChuteCore

private func requireGitRepo(_ dir: String) {
    let r = Shell.run("git", ["rev-parse", "--is-inside-work-tree"], cwd: dir)
    guard r.ok else { Out.fail("not a git repository: \(dir)") }
}

// MARK: - FR-09 pre-agent checkpoint

/// NFR-08 — uses `git stash create`, which builds a commit object from the working tree
/// WITHOUT touching the index, the worktree, or the current branch. Nothing is ever moved
/// out from under the user; this command can only add.
func cmdCheckpoint(_ a: Args) {
    let dir = a.paths(defaultToCWD: true)[0]
    requireGitRepo(dir)
    let f = DateFormatter(); f.dateFormat = "yyyyMMdd-HHmmss"
    let branch = "chute/checkpoint-\(f.string(from: Date()))"

    // A private index file: `git add -A` against it stages the whole worktree — tracked,
    // modified AND untracked — without ever touching the user's real index or HEAD.
    let indexPath = (NSTemporaryDirectory() as NSString)
        .appendingPathComponent("chute-index-\(UUID().uuidString)")
    defer { try? FileManager.default.removeItem(atPath: indexPath) }
    let env = ["GIT_INDEX_FILE": indexPath]

    let added = Shell.run("git", ["add", "-A"], cwd: dir, env: env)
    guard added.ok else { Out.fail("git add failed: \(added.err.trimmingCharacters(in: .whitespacesAndNewlines))") }

    let tree = Shell.run("git", ["write-tree"], cwd: dir, env: env)
        .out.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !tree.isEmpty else { Out.fail("could not write a tree object") }

    // Identity only if the repo has none — never override the user's configured author.
    var identity: [String] = []
    if Shell.run("git", ["config", "user.email"], cwd: dir).out
        .trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        identity = ["-c", "user.name=chute", "-c", "user.email=chute@local"]
    }
    let head = Shell.run("git", ["rev-parse", "HEAD"], cwd: dir)
        .out.trimmingCharacters(in: .whitespacesAndNewlines)
    let parents = head.isEmpty ? [] : ["-p", head]

    let made = Shell.run("git", identity + ["commit-tree", tree] + parents
                         + ["-m", "chute checkpoint \(f.string(from: Date()))"],
                         cwd: dir, env: env)
    let commit = made.out.trimmingCharacters(in: .whitespacesAndNewlines)
    guard made.ok, !commit.isEmpty else {
        Out.fail("could not create the checkpoint commit: \(made.err.trimmingCharacters(in: .whitespacesAndNewlines))")
    }
    let branched = Shell.run("git", ["branch", branch, commit], cwd: dir)
    guard branched.ok else {
        Out.fail("could not create \(branch): \(branched.err.trimmingCharacters(in: .whitespacesAndNewlines))")
    }
    Out.line(branch)
    Out.info("→ every file snapshotted, worktree untouched · restore with: git checkout \(branch)")
}

// MARK: - FR-13 diff snapshot

func cmdDiff(_ a: Args) {
    let dir = a.paths(defaultToCWD: true)[0]
    requireGitRepo(dir)
    let stat = Shell.run("git", ["diff", "--stat", "HEAD"], cwd: dir)
    let untracked = Shell.run("git", ["ls-files", "--others", "--exclude-standard"], cwd: dir)
        .out.split(separator: "\n").map(String.init)

    let body = stat.out.isEmpty ? "(no tracked changes)" : stat.out
    Out.line(body)
    if !untracked.isEmpty {
        Out.line("untracked (\(untracked.count)):")
        untracked.prefix(20).forEach { Out.line("  + \($0)") }
    }
    if a.has("copy") {
        let patch = Shell.run("git", ["diff", "HEAD"], cwd: dir).out
        Clipboard.write(patch)
        Out.info("→ full patch copied (\(TokenEstimate.badge(TokenEstimate.tokens(in: patch))))")
    }
}

// MARK: - FR-20 secret gist

func cmdGist(_ a: Args) {
    guard Shell.which("gh") != nil else {
        Out.fail("gh is not installed — `brew install gh`, then `gh auth login`")
    }
    let files = a.paths()
    guard !files.isEmpty else { Out.fail("usage: chute gist <files…>") }

    // Redact BEFORE anything leaves this machine. A "secret" gist is unlisted, not private,
    // and this is the one command that uploads — the help text says so and promises this step.
    // Staged copies keep their basenames so the gist reads the same as the originals.
    let stage = NSTemporaryDirectory() + "chute-gist-\(UUID().uuidString)"
    do { try FileManager.default.createDirectory(atPath: stage, withIntermediateDirectories: true) }
    catch { Out.fail("cannot stage gist: \(error.localizedDescription)") }
    defer { try? FileManager.default.removeItem(atPath: stage) }
    var staged: [String] = []
    var redacted = 0
    for (i, file) in files.enumerated() {
        var dest = (stage as NSString).appendingPathComponent((file as NSString).lastPathComponent)
        if FileManager.default.fileExists(atPath: dest) {   // two selections, same basename
            dest = (stage as NSString).appendingPathComponent("\(i)-" + (file as NSString).lastPathComponent)
        }
        if let text = try? String(contentsOfFile: file, encoding: .utf8) {
            let clean = Redact.apply(text)
            if clean != text { redacted += 1 }
            do { try clean.write(toFile: dest, atomically: true, encoding: .utf8) }
            catch { Out.fail("cannot stage \(file): \(error.localizedDescription)") }
        } else {
            // Not UTF-8 text (an image, an archive) — nothing the redactor can scan; upload as-is.
            do { try FileManager.default.copyItem(atPath: file, toPath: dest) }
            catch { Out.fail("cannot read \(file): \(error.localizedDescription)") }
        }
        staged.append(dest)
    }
    let r = Shell.run("gh", ["gist", "create", "--secret"] + staged)
    guard r.ok else { Out.fail("gh failed: \(r.err.trimmingCharacters(in: .whitespacesAndNewlines))") }
    let url = (r.out + r.err).split(separator: "\n")
        .last(where: { $0.hasPrefix("https://") })
        .map(String.init) ?? r.out.trimmingCharacters(in: .whitespacesAndNewlines)
    Clipboard.write(url)
    Out.line(url)
    Out.info(redacted > 0
             ? "→ copied to clipboard · secrets redacted in \(redacted) file(s) before upload"
             : "→ copied to clipboard · nothing to redact")
}
