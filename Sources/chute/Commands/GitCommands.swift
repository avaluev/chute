import Foundation
import ChuteCore

/// git's own hash of the empty tree — the same value in every repository ever created, which is
/// why it can be a constant rather than something to look up.
enum CheckpointConstants {
    static let emptyTree = "4b825dc642cb6eb9a060e54bf8d69288fbee4904"
}

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
    let stamp = f.string(from: Date())

    // A private index file: `git add -A` against it stages the whole worktree — tracked,
    // modified AND untracked — without ever touching the user's real index or HEAD.
    let indexPath = (NSTemporaryDirectory() as NSString)
        .appendingPathComponent("chute-index-\(UUID().uuidString)")
    defer { try? FileManager.default.removeItem(atPath: indexPath) }
    let env = ["GIT_INDEX_FILE": indexPath]

    // `git add -A` is FATAL on a nested repository that has no commit yet —
    // "error: 'x/' does not have a commit checked out" — and that state is exactly one
    // right-click away: "Set Up for an Agent ▸ New Scratch Folder" git-inits a folder inside
    // this one. Snapshotting NOTHING because one subfolder is odd is the opposite of what a
    // checkpoint is for, so it is best-effort: `--ignore-errors` skips what it cannot index and
    // keeps everything else. Nothing is lost — an empty repo has no commit for git to reference.
    //
    // Success is therefore judged on `write-tree` below, not on add's exit code: --ignore-errors
    // still exits non-zero when it skipped something, which is information, not failure.
    let added = Shell.run("git", ["add", "-A", "--ignore-errors"], cwd: dir, env: env)
    let skippedSomething = !added.ok

    let tree = Shell.run("git", ["write-tree"], cwd: dir, env: env)
        .out.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !tree.isEmpty else { Out.fail("could not write a tree object") }

    // "Some paths were left out" must never be how a user learns that EVERY path was left out.
    // `git write-tree` against an index that staged nothing cheerfully emits git's empty tree and
    // exits 0 — so a folder where nothing is indexable (a permissions-broken directory, an
    // external volume) would mint a branch, print a restore command, and hold nothing. A safety
    // net that reports itself as saved-with-caveats while empty is discovered on the one day it
    // is needed. The conjunction matters: an actually-empty repo stages nothing WITHOUT error,
    // and checkpointing it is correct.
    if skippedSomething && tree == CheckpointConstants.emptyTree {
        Out.fail("nothing here could be indexed, so the checkpoint would be empty — "
               + "check the folder's permissions and try again")
    }

    // Identity only if the repo has none — never override the user's configured author.
    var identity: [String] = []
    if Shell.run("git", ["config", "user.email"], cwd: dir).out
        .trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        identity = ["-c", "user.name=chute", "-c", "user.email=chute@local"]
    }
    // `git rev-parse HEAD` on a repo with no commits yet prints the literal string "HEAD" on
    // stdout and fails on stderr, so a plain emptiness check reads it as a real parent and
    // commit-tree then dies with "not a valid object name HEAD". A fresh `git init` is not an
    // edge case here: "Set Up for an Agent ▸ New Scratch Folder" produces one every time.
    // `--verify -q` prints nothing and exits non-zero instead, which is the question being asked.
    let headResult = Shell.run("git", ["rev-parse", "--verify", "-q", "HEAD^{commit}"], cwd: dir)
    let head = headResult.ok
        ? headResult.out.trimmingCharacters(in: .whitespacesAndNewlines) : ""
    let parents = head.isEmpty ? [] : ["-p", head]

    let made = Shell.run("git", identity + ["commit-tree", tree] + parents
                         + ["-m", "chute checkpoint \(stamp)"],
                         cwd: dir, env: env)
    let commit = made.out.trimmingCharacters(in: .whitespacesAndNewlines)
    guard made.ok, !commit.isEmpty else {
        Out.fail("could not create the checkpoint commit: \(made.err.trimmingCharacters(in: .whitespacesAndNewlines))")
    }
    // The short sha, not just the timestamp: the name is stamped to the second, and an unchanged
    // worktree checkpointed twice in the same second produces the byte-identical commit — so the
    // old name collided with itself and `git branch` refused. Clicking a safety net twice must
    // never be an error, so an existing branch already pointing at this exact commit is success,
    // not failure. The sha also makes the branch name say which snapshot it is.
    let branch = "chute/checkpoint-\(stamp)-\(commit.prefix(7))"
    let existing = Shell.run("git", ["rev-parse", "--verify", "-q", branch + "^{commit}"], cwd: dir)
    func pointsAtOurCommit() -> Bool {
        Shell.run("git", ["rev-parse", "--verify", "-q", branch + "^{commit}"], cwd: dir)
            .out.trimmingCharacters(in: .whitespacesAndNewlines) == commit
    }
    if existing.out.trimmingCharacters(in: .whitespacesAndNewlines) != commit {
        let branched = Shell.run("git", ["branch", branch, commit], cwd: dir)
        // Re-check before failing. Two checkpoints of the same worktree can both pass the test
        // above and race here; the loser's `git branch` fails with "already exists" even though
        // the branch now points at exactly the commit it wanted. That is the goal, not an error.
        guard branched.ok || pointsAtOurCommit() else {
            Out.fail("could not create \(branch): \(branched.err.trimmingCharacters(in: .whitespacesAndNewlines))")
        }
    }
    Out.line(branch)
    // The wording is the honest one for each case: a checkpoint that quietly left files out and
    // said "every file" is the kind of promise that is only discovered when it is needed.
    Out.info(skippedSomething
        ? "→ snapshotted, worktree untouched — some paths could not be indexed and were left out · restore with: git checkout \(branch)"
        : "→ every file snapshotted, worktree untouched · restore with: git checkout \(branch)")
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
        ContextBuffer().record(patch, label: "Diff · what the agent changed")
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
    // 0700. Non-text files are staged UNREDACTED ("upload as-is" below), and staging happens even
    // on the dry-run path, so for the life of this command the user's files sit in a directory the
    // umask would otherwise leave at 755. Not exploitable under the default $TMPDIR — /var/folders
    // is already 700 and owner-only — but that is macOS's doing, not this code's, and every other
    // sensitive path here already sets its own mode (ContextBuffer 0700, RequestInbox 0600, .env
    // 0600). Depending on someone else's default is not the same as being right.
    do { try FileManager.default.createDirectory(atPath: stage, withIntermediateDirectories: true,
                                                 attributes: [.posixPermissions: NSNumber(value: 0o700)]) }
    catch { Out.fail("cannot stage gist: \(error.localizedDescription)") }
    defer { try? FileManager.default.removeItem(atPath: stage) }
    var staged: [String] = []
    var redactedFiles: [String] = []
    for (i, file) in files.enumerated() {
        var dest = (stage as NSString).appendingPathComponent((file as NSString).lastPathComponent)
        if FileManager.default.fileExists(atPath: dest) {   // two selections, same basename
            dest = (stage as NSString).appendingPathComponent("\(i)-" + (file as NSString).lastPathComponent)
        }
        if let text = try? String(contentsOfFile: file, encoding: .utf8) {
            let clean = Redact.apply(text)
            if clean != text { redactedFiles.append(file) }
            do { try clean.write(toFile: dest, atomically: true, encoding: .utf8) }
            catch { Out.fail("cannot stage \(file): \(error.localizedDescription)") }
        } else {
            // Not UTF-8 text (an image, an archive) — nothing the redactor can scan; upload as-is.
            do { try FileManager.default.copyItem(atPath: file, toPath: dest) }
            catch { Out.fail("cannot read \(file): \(error.localizedDescription)") }
        }
        staged.append(dest)
    }

    // NFR-05 — preview by default, upload only with --force. Staging (including redaction) above
    // only ever touches a scratch dir under `stage`, cleaned by the `defer`; nothing has left this
    // machine yet. Once `gh gist create` runs it is on GitHub whatever happens next.
    guard a.has("force") else {
        Out.info("dry run — \(files.count) file(s) would be uploaded as a secret gist:")
        files.forEach { Out.line("  \($0)") }
        Out.info(redactedFiles.isEmpty
                 ? "  nothing to redact"
                 : "  secrets redacted in: \(redactedFiles.joined(separator: ", "))")
        Out.info("→ re-run with --force to upload")
        return
    }

    let r = Shell.run("gh", ["gist", "create", "--secret"] + staged)
    guard r.ok else { Out.fail("gh failed: \(r.err.trimmingCharacters(in: .whitespacesAndNewlines))") }
    let url = (r.out + r.err).split(separator: "\n")
        .last(where: { $0.hasPrefix("https://") })
        .map(String.init) ?? r.out.trimmingCharacters(in: .whitespacesAndNewlines)
    Clipboard.write(url)
    ContextBuffer().record(url, label: "Secret gist URL")
    Out.line(url)
    Out.info(redactedFiles.isEmpty
             ? "→ copied to clipboard · nothing to redact"
             : "→ copied to clipboard · secrets redacted in \(redactedFiles.count) file(s) before upload")
}
