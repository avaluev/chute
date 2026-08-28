import Foundation
import ChuteCore

let files3 = ["/tmp/proj/src/a.ts", "/tmp/proj/src/b.ts", "/tmp/proj/README.md"]

func coreSuites() {
    // MARK: - FR-01 path formatting
    T.suite("PathFormat") {
        T.eq(PathFormat.commonAncestor(files3), "/tmp/proj", "common ancestor")
        T.eq(PathFormat.commonAncestor(["/tmp/proj/a.ts"]), "/tmp/proj", "ancestor of one file is its parent")
        T.eq(PathFormat.render(files3, style: .posix), files3.joined(separator: "\n"), "posix absolute per line")
        T.eq(PathFormat.render(files3, style: .relative), "src/a.ts\nsrc/b.ts\nREADME.md", "relative to ancestor")
        T.eq(PathFormat.render(files3, style: .at, separator: .space), "@src/a.ts @src/b.ts @README.md", "@ mentions")
        T.eq(PathFormat.render(["/tmp/my docs/it's.txt"], style: .quoted), "'/tmp/my docs/it'\\''s.txt'", "quoted escapes spaces and quotes")
        T.eq(PathFormat.render(files3, style: .posix, separator: .space), files3.joined(separator: " "), "space separator")
        T.eq(PathFormat.render([], style: .posix), "", "empty input")
    }

    // MARK: - FR-03 token estimate
    T.suite("TokenEstimate") {
        T.eq(TokenEstimate.tokens(in: String(repeating: "a", count: 400)), 100, "~4 chars per token")
        T.eq(TokenEstimate.tokens(in: ""), 0, "empty is zero")
        T.eq(TokenEstimate.tokens(in: "ab"), 1, "partial token rounds up")
        T.eq(TokenEstimate.badge(32_000), "~32k tokens", "k badge")
        T.eq(TokenEstimate.badge(850), "~850 tokens", "small badge")
    }

    // MARK: - FR-05 language detection
    T.suite("LanguageDetect") {
        T.eq(LanguageDetect.fileExtension(for: "whatever", hint: "python"), "py", "hint python")
        T.eq(LanguageDetect.fileExtension(for: "whatever", hint: "ts"), "ts", "hint ts")
        T.eq(LanguageDetect.fileExtension(for: "{\"a\": 1, \"b\": [2,3]}"), "json", "json body")
        T.eq(LanguageDetect.fileExtension(for: "#!/usr/bin/env python3\nprint(1)"), "py", "python shebang")
        T.eq(LanguageDetect.fileExtension(for: "#!/bin/bash\necho hi"), "sh", "bash shebang")
        T.eq(LanguageDetect.fileExtension(for: "import Foundation\nfunc main() {}"), "swift", "swift body")
        T.eq(LanguageDetect.fileExtension(for: "SELECT id FROM users WHERE x = 1;"), "sql", "sql body")
        T.eq(LanguageDetect.fileExtension(for: "# Title\n\nsome prose here"), "md", "markdown heading")
        T.eq(LanguageDetect.fileExtension(for: "just a plain sentence."), "md", "prose defaults to md")
    }

    // MARK: - FR-04 name derivation
    T.suite("NameDerive") {
        T.eq(NameDerive.slug(fromMarkdown: "# My Great Spec!\n\nbody"), "my-great-spec", "slug from heading")
        T.eq(NameDerive.slug(fromMarkdown: "intro\n## Second\n# First\n"), "second", "first heading of any level wins")
        T.ok(NameDerive.slug(fromMarkdown: "no headings here") == nil, "nil without heading")
        T.ok((NameDerive.slug(fromMarkdown: "# " + String(repeating: "word ", count: 40)) ?? "").count <= 60, "long heading truncated")
        let taken: Set<String> = ["/d/spec.md", "/d/spec-2.md"]
        T.eq(NameDerive.uniquePath(dir: "/d", base: "spec", ext: "md") { taken.contains($0) }, "/d/spec-3.md", "never overwrites")
        T.eq(NameDerive.uniquePath(dir: "/d", base: "spec", ext: "md") { _ in false }, "/d/spec.md", "plain name when free")
    }

    // MARK: - FR-02 context bundle
    T.suite("ContextBundle") {
        let bundle = [BundleFile(path: "/p/a.ts", content: "let a = 1"),
                      BundleFile(path: "/p/b.md", content: "# B")]
        let xml = ContextBundle.xml(bundle, root: "/p")
        T.ok(xml.contains("<file path=\"a.ts\">"), "xml wraps each file")
        T.ok(xml.contains("let a = 1"), "xml keeps content")
        let esc = ContextBundle.xml([BundleFile(path: "/p/x.html", content: "<a href=\"y\">&</a>")], root: "/p")
        T.ok(esc.contains("<a href=\"y\">&</a>"), "code content stays raw — no entity soup")
        T.no(esc.contains("&lt;"), "no escaping inside the body")
        let gen = ContextBundle.xml([BundleFile(path: "/p/g.swift", content: "let x: Set<String> = []")], root: "/p")
        T.ok(gen.contains("Set<String>"), "generics survive intact")
        let tricky = ContextBundle.xml([BundleFile(path: "/p/t.md", content: "text </file> more")], root: "/p")
        T.eq(tricky.components(separatedBy: "</file>").count - 1, 1, "a literal closing tag in the body cannot break the wrapper")
        let quoted = ContextBundle.xml([BundleFile(path: "/p/say \"hi\".txt", content: "x")], root: "/p")
        T.ok(quoted.contains("&quot;"), "path attribute is still escaped")
        T.ok(ContextBundle.markdown(bundle, root: "/p").contains("```ts a.ts"), "md fence carries language + path")
    }

    // MARK: - FR-06 markdown unpacker
    T.suite("MarkdownUnpack") {
        let onFence = MarkdownUnpack.parse("```ts src/auth.ts\nexport const x = 1\n```")
        T.eq(onFence.count, 1, "one file from fence info line")
        T.eq(onFence.first?.path ?? "", "src/auth.ts", "path on fence info line")
        T.eq(onFence.first?.content ?? "", "export const x = 1", "content preserved")
        T.eq(MarkdownUnpack.parse("### src/db.ts\n\n```ts\nconst db = 1\n```").first?.path ?? "", "src/db.ts", "path from heading")
        T.eq(MarkdownUnpack.parse("**config/app.json**\n```json\n{}\n```").first?.path ?? "", "config/app.json", "path from bold line")
        let multi = MarkdownUnpack.parse("### a.ts\n```ts\n1\n```\n### b.py\n```python\n2\n```")
        T.eq(multi.map(\.path), ["a.ts", "b.py"], "multiple files")
        T.eq(multi.map(\.content), ["1", "2"], "multiple contents")
        T.ok(MarkdownUnpack.parse("```\nplain\n```").isEmpty, "unnamed blocks skipped")
        T.throwsError("rejects absolute path") { _ = try MarkdownUnpack.validate([UnpackedFile(path: "/etc/passwd", content: "x")]) }
        T.throwsError("rejects parent traversal") { _ = try MarkdownUnpack.validate([UnpackedFile(path: "../../etc/passwd", content: "x")]) }
        T.noThrow("accepts nested relative path") { _ = try MarkdownUnpack.validate([UnpackedFile(path: "a/b/c.ts", content: "x")]) }
    }

    // MARK: - FR-19 redaction
    T.suite("Redact") {
        T.no(Redact.apply("key: sk-ant-api03-AbCdEfGhIjKlMnOpQrStUvWxYz012345").contains("AbCdEfGh"), "anthropic key gone")
        T.ok(Redact.apply("key: sk-ant-api03-AbCdEfGhIjKlMnOpQrStUvWxYz012345").contains("[REDACTED]"), "marker present")
        T.no(Redact.apply("ghp_ABCDEFGHIJKLMNOPQRSTUVWXYZ012345").contains("ABCDEFGH"), "github token gone")
        T.no(Redact.apply("AKIAIOSFODNN7EXAMPLE").contains("IOSFODNN7"), "aws key gone")
        T.no(Redact.apply("Authorization: Bearer abcdef123456789012345").contains("abcdef1234"), "bearer gone")
        let env = Redact.apply("OPENAI_API_KEY=super-secret-value-here")
        T.ok(env.contains("OPENAI_API_KEY="), "env key name kept")
        T.no(env.contains("super-secret-value-here"), "env value gone")
        T.eq(Redact.apply("just some normal prose about keys and tokens"), "just some normal prose about keys and tokens", "innocent text untouched")

        // SECURITY — formats an audit found the list walking straight past. Every one of these
        // is reachable through `chute gist`, which redacts and then UPLOADS.
        // ASSEMBLED, NEVER WRITTEN OUT. A key-shaped literal in a test file is still a
        // key-shaped literal to a scanner: GitHub's push protection rejected this very commit
        // over the Stripe line, which held Stripe's own published example value. Concatenating
        // the prefix exercises the same regex without putting the shape in the file — and the
        // block was the right call, because nothing can tell a real key from a documented one.
        let ghPat = "github" + "_pat_" + "11ABCDE0Y0aBcDeFgHiJkL" + "_mNoPqRsTuVwXyZ0123456789"
        T.no(Redact.apply(ghPat).contains("mNoPqRsTuVwXyZ"),
             "github fine-grained PAT gone — the default GitHub issues now")
        let awsTemp = "ASIA" + "Y34FZKBOKMUTVV7A"
        T.no(Redact.apply(awsTemp).contains("Y34FZKBOK"), "aws temporary credential gone")
        let stripeSecret = "sk_" + "live_" + "51H8sJkQwErTyUiOpAsDfGh"
        T.no(Redact.apply(stripeSecret).contains("51H8sJkQwErTy"), "stripe secret key gone")
        let stripePublishable = "pk_" + "live_" + "51H8sJkQwErTyUiOpAsDfGh"
        T.ok(Redact.apply(stripePublishable).contains("51H8sJkQwErTy"),
             "but a publishable key is left alone — it is public by design")
        let lower = Redact.apply("api_key=super-secret-value-here")
        T.ok(lower.contains("api_key="), "a lowercase env key name is kept")
        T.no(lower.contains("super-secret-value-here"), "and its value is gone — dotenv does not care about case")
        let conn = Redact.apply("Server=db.example.com;Uid=root;Pwd=hunter2;Database=app")
        T.no(conn.contains("hunter2"), "a semicolon-delimited connection string password is gone")
        T.ok(conn.contains("Server=db.example.com"), "and the rest of the string survives")
        T.no(Redact.apply("redis://:hunter2@cache:6379").contains("hunter2"),
             "a URL password with no username — the ordinary Redis shape — is masked")

        // SECURITY — the two leaks the pattern list did not catch.
        T.ok(Redact.apply("db=postgres://admin:hunter2@localhost/app").contains("[REDACTED]@"),
             "credentials inside a URL are masked — no key-shaped pattern would catch them")
        T.ok(!Redact.apply("db=postgres://admin:hunter2@localhost/app").contains("hunter2"),
             "and the password itself is gone")
        T.ok(Redact.apply("mysql://root@localhost/db").contains("root@localhost"),
             "a URL with no password is left alone")
        let key = "-----BEGIN RSA PRIVATE KEY-----\nMIIabc\nMORE\n-----END RSA PRIVATE KEY-----"
        T.eq(Redact.apply(key), "[REDACTED]", "a private key block is removed whole, not line by line")
        T.ok(!Redact.apply("before\n" + key + "\nafter").contains("MIIabc"),
             "including when it is embedded in other text")
        T.ok(Redact.apply("before\n" + key + "\nafter").contains("before"),
             "and the surrounding text survives")

        // SECURITY — a path that escapes through a symlink already sitting in the target folder.
        let box = NSTemporaryDirectory() + "chute-escape-\(UInt32.random(in: 0...99999))"
        let inside = (box as NSString).appendingPathComponent("safe")
        let outside = (box as NSString).appendingPathComponent("outside")
        try? FileManager.default.createDirectory(atPath: inside, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(atPath: outside, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(atPath: box) }
        try? FileManager.default.createSymbolicLink(
            atPath: (inside as NSString).appendingPathComponent("link"), withDestinationPath: outside)

        T.ok(MarkdownUnpack.staysInside(dir: inside, path: "src/app.ts"),
             "an ordinary nested path is inside")
        T.ok(MarkdownUnpack.staysInside(dir: inside, path: "app.ts"),
             "and so is a file at the top")
        T.ok(!MarkdownUnpack.staysInside(dir: inside, path: "link/pwned.txt"),
             "a path through a symlink that leaves the folder is refused")
        T.ok(!MarkdownUnpack.staysInside(dir: inside, path: "../pwned.txt"),
             "and so is a plain climb, belt and braces with validate()")
    }

    T.suite("FileScan.expand") {
        // THE BUG THIS EXISTS FOR. `clean` is the one command LOOKING for junk, and the walk was
        // dropping junk before it ever saw it — so every `.log`, `.tmp`, `.bak`, `.swp`, `.orig`
        // and `.rej` on disk was invisible to it and only the scratch PREFIXES ever got listed.
        // Silently removing half of what a command advertises is worse than failing at it.
        let dir = NSTemporaryDirectory() + "chute-scan-\(UUID().uuidString)"
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(atPath: dir) }
        for name in ["keep.ts", "temp_agent.log", "notes.bak", ".env", ".DS_Store"] {
            FileManager.default.createFile(atPath: (dir as NSString).appendingPathComponent(name),
                                           contents: Data())
        }
        func names(_ paths: [String]) -> Set<String> {
            Set(paths.map { ($0 as NSString).lastPathComponent })
        }
        let context = names(FileScan.expand([dir]))
        T.eq(context, ["keep.ts"], "building context sees only real files — junk is wasted tokens")

        let sweep = names(FileScan.expand([dir], includingJunk: true))
        T.ok(sweep.contains("temp_agent.log") && sweep.contains("notes.bak"),
             "a junk sweep sees the scratch files a context build hides")
        T.ok(sweep.contains(".env"), "and everything else, so the DECISION is made in one place")

        // …which is `isAgentScratch`, and it is what keeps a secret out of the Trash. `clean`
        // filters the sweep through this, so widening the walk above widened nothing destructive.
        T.ok(!Junk.isAgentScratch(name: ".env"), "a .env is never an agent's scratch file")
        T.ok(!Junk.isAgentScratch(name: ".DS_Store"), "nor is a Finder file the user did not make")
        T.ok(Junk.isAgentScratch(name: "temp_agent.log"), "a scratch extension is")
        T.ok(Junk.isAgentScratch(name: "scratch_notes.md"), "and so is a scratch prefix")
    }

    T.suite("Shell") {
        // A child that floods stderr while its stdout is still open used to deadlock BOTH
        // processes: the ~64 KB pipe filled, the child blocked mid-write, stdout never closed,
        // readDataToEndOfFile never returned. Completing at all is the assertion — a regression
        // here hangs the suite, which is the loudest possible failure.
        let flood = Shell.run("sh", ["-c", "head -c 200000 /dev/zero | tr '\\0' e 1>&2; echo done"])
        T.eq(flood.out.trimmingCharacters(in: .whitespacesAndNewlines), "done",
             "stdout survives a 200 KB stderr flood")
        T.eq(flood.err.count, 200_000, "and every stderr byte is captured, not truncated")
    }
}
