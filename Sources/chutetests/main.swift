import Foundation
import ChuteCore

let files3 = ["/tmp/proj/src/a.ts", "/tmp/proj/src/b.ts", "/tmp/proj/README.md"]

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
    T.ok(esc.contains("&lt;a href=&quot;y&quot;&gt;&amp;&lt;/a&gt;"), "xml escapes markup")
    T.no(esc.contains("<a href"), "raw markup gone")
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
}

T.report()
