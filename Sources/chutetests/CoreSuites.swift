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
        // An @mention ends at a space. `@my docs/note one.txt @a.ts` is four tokens to the agent.
        T.eq(PathFormat.render(["/p/my docs/note one.txt", "/p/a.ts"], style: .at, separator: .space),
             "@my docs/note one.txt\n@a.ts", "@ mentions go one per line the moment any path has a space")
        T.eq(PathFormat.render(["/p/my docs/x.txt", "/p/a.ts"], style: .posix, separator: .space),
             "/p/my docs/x.txt /p/a.ts", "the other styles keep the separator they were asked for")
        T.eq(PathFormat.render(["/tmp/my docs/it's.txt"], style: .quoted), "'/tmp/my docs/it'\\''s.txt'", "quoted escapes spaces and quotes")
        T.eq(PathFormat.render(files3, style: .posix, separator: .space), files3.joined(separator: " "), "space separator")
        T.eq(PathFormat.render([], style: .posix), "", "empty input")
    }

    // MARK: - FR-03 token estimate
    T.suite("TokenEstimate") {
        T.eq(TokenEstimate.tokens(in: String(repeating: "a", count: 400)), 100, "~4 chars per token")
        T.eq(TokenEstimate.tokens(in: ""), 0, "empty is zero")
        T.eq(TokenEstimate.tokens(in: "ab"), 1, "partial token rounds up")
        // The count is UTF-8 BYTES, not characters. "é" is one Character and two bytes; a model
        // is billed for the two. This assertion is what stops someone "simplifying" it back to
        // `text.count`, which is both slower and cheaper than the truth.
        T.eq(TokenEstimate.tokens(in: "\u{1F600}"), 1, "an emoji is 4 bytes, not 1 character")
        T.eq(TokenEstimate.tokens(in: String(repeating: "é", count: 200)), 100, "2 bytes each, not 1")
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

    // FR-06 markdown unpacker (`MarkdownUnpack`) removed 2026-08-31 with `chute unpack` — see
    // docs/specs/move-5-delete-unpack.md. Its two suites (parse/validate here, staysInside below
    // near FileScan.expand) went with it.

    // MARK: - FR-19 redaction
    T.suite("FileScan.absolute") {
        // A path a human is going to read and paste. `.` used to survive into the middle of
        // every path `clean`, `seed`, `note`, `latest` and `unpack` printed.
        let cwd = FileManager.default.currentDirectoryPath
        T.eq(FileScan.absolute("."), cwd, "'.' is the directory itself, not '<dir>/.'")
        // REGRESSION. `standardizingPath` was the tidy-looking way to do this and it also
        // resolves symlinks, which silently broke `bundle`: it renders paths relative to the
        // working directory, and resolving one side and not the other collapsed every file in a
        // bundle to its bare name. Whatever this does to dots, it must not move the prefix.
        T.eq(FileScan.absolute("/var/folders/x/./y.txt"), "/var/folders/x/y.txt",
             "a dot goes without /var being resolved to /private/var")
        T.no(FileScan.absolute("./x.txt").contains("/./"), "and no './' survives into a joined path")
        T.eq(FileScan.absolute("/a/././b"), "/a/b", "adjacent dots are all removed, not every other one")
        T.no(FileScan.absolute(".").hasSuffix("/."), "nor a trailing one")
        T.ok(FileScan.absolute("/already/absolute.txt") == "/already/absolute.txt",
             "an absolute path is left exactly as it is")
        T.ok(FileScan.absolute("~").hasPrefix("/"), "a tilde still expands")
    }

    T.suite("Redact") {
        // QUOTED VALUES. The inline rule excluded quote characters from the value, so a quoted
        // secret — the ordinary way to write one — was walked straight past and then uploaded by
        // `chute gist`. Not one of the twenty-four assertions below used a quote.
        T.no(Redact.apply(#"export TOKEN="ghs_abcdefghijklmnop""#).contains("ghs_abc"),
             "a double-quoted token is masked")
        T.no(Redact.apply(#"docker run -e MYSQL_ROOT_PASSWORD='hunter2' mysql"#).contains("hunter2"),
             "and a single-quoted password inside a command line")
        T.eq(Redact.apply("Server=db;Pwd=hunter2;Database=app"), "Server=db;Pwd=[REDACTED];Database=app",
             "the semicolon-delimited connection string still stops at the semicolon")
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

    }

    T.suite("FileScan.expand") {
        // THE BUG THIS EXISTS FOR. `clean` is the one command LOOKING for junk, and the walk was
        // dropping junk before it ever saw it — so every `.log`, `.tmp`, `.bak`, `.swp`, `.orig`
        // and `.rej` on disk was invisible to it and only the scratch PREFIXES ever got listed.
        // Silently removing half of what a command advertises is worse than failing at it.
        let dir = NSTemporaryDirectory() + "chute-scan-\(UUID().uuidString)"
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(atPath: dir) }

        // THE BYTE CAP. `maxFiles` bounded the count and nothing bounded the size of one file, so
        // "Copy Files as Context" over a folder with a 1 GB dump read the whole thing into memory
        // three times and hung with no message. Text one byte over the cap is skipped like a
        // binary; text at the cap is read.
        let big = dir + "/dump.sql", fits = dir + "/fits.sql"
        FileManager.default.createFile(atPath: big, contents: Data(repeating: 0x61, count: FileScan.maxFileBytes + 1))
        FileManager.default.createFile(atPath: fits, contents: Data(repeating: 0x61, count: FileScan.maxFileBytes))
        T.eq(FileScan.readText(big), nil, "a text file over maxFileBytes is skipped, not read into memory")
        T.eq(FileScan.readText(fits)?.utf8.count, FileScan.maxFileBytes, "one exactly at the cap is read whole")
        T.eq(FileScan.bundleFiles([big, fits]).skipped, [big], "and the bundle lists it as skipped")
        try? FileManager.default.removeItem(atPath: big); try? FileManager.default.removeItem(atPath: fits)

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
        T.no(Junk.isAgentScratch(name: "Untitled.md"),
             "Untitled.md is what New File ▸ Empty Markdown creates — clean must not propose trashing it")
    }

    // MARK: - Move 3: `chute --version` must be able to say it is stale
    T.suite("VersionLine") {
        // `chute --version` builds this line the same way `chute doctor` already does — see the
        // `versionLine` constant in Sources/chute/main.swift, which cannot be imported here (an
        // executable target, not a library). Testing the STRING built from ChuteVersion.current +
        // Diagnostics.installedBuild(), not plist-reading: DiagnosticsSuite already proves
        // installedBuild() itself reads a stamped plist correctly.
        func versionLine(appPath: String) -> String {
            "chute \(ChuteVersion.current) · app build "
                + (Diagnostics.installedBuild(appPath: appPath) ?? "not stamped — rebuild with ./Scripts/build-app.sh")
        }

        T.ok(versionLine(appPath: "/tmp/no-such-chute-app-\(UUID().uuidString).app").contains("not stamped"),
             "no stamp reads as not stamped, never as current")

        let bundle = NSTemporaryDirectory() + "chute-versionline-\(UUID().uuidString)/Chute.app/Contents"
        try? FileManager.default.createDirectory(atPath: bundle, withIntermediateDirectories: true)
        let stampedApp = (bundle as NSString).deletingLastPathComponent
        let plist = (bundle as NSString).appendingPathComponent("Info.plist")
        try? NSDictionary(dictionary: ["ChuteBuild": "abc1234 2026-08-29T12:00Z"])
            .write(toFile: plist, atomically: true)
        T.eq(versionLine(appPath: stampedApp),
             "chute \(ChuteVersion.current) · app build abc1234 2026-08-29T12:00Z",
             "the stamp is present in the version string when the app is stamped")
        try? FileManager.default.removeItem(atPath: (stampedApp as NSString).deletingLastPathComponent)
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

        // A child that never reads stdin — pbcopy where there is no pasteboard server — made the
        // stdin write an EPIPE, and the non-throwing write turned that into SIGPIPE: exit 141,
        // no result, no message. Returning at all is the assertion.
        let unread = Shell.run("true", [], input: String(repeating: "x", count: 300_000))
        T.eq(unread.code, 0, "a child that exits without reading 300 KB of stdin is a result, not a signal")
    }
}
