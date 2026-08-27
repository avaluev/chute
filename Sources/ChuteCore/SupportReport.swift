import Foundation

/// Support without an inbox.
///
/// A problem report is only useful if it carries what the developer needs and nothing the user
/// would regret sending. This builds that: the check results, the versions, and whether the Finder
/// extension ever actually started — run through the same redaction the product already uses for
/// sharing files, because a path can contain a token and a check detail can contain a path.
public enum SupportReport {
    public static let issuesURL = "https://github.com/avaluev/chute/issues/new"

    /// The report body. `extras` lets the caller add environment lines without this type having to
    /// know how to find them.
    public static func build(outcomes: [CheckOutcome],
                             version: String,
                             osVersion: String,
                             extras: [String: String] = [:]) -> String {
        var lines: [String] = []
        lines.append("## What happened")
        lines.append("")
        lines.append("<!-- What did you click, and what did you expect instead? -->")
        lines.append("")
        lines.append("## Diagnostics")
        lines.append("")
        lines.append("```")
        lines.append("chute \(version) · macOS \(osVersion)")
        for key in extras.keys.sorted() {
            lines.append("\(key): \(extras[key] ?? "")")
        }
        lines.append("")
        for outcome in outcomes {
            lines.append("\(outcome.passed ? "PASS" : "FAIL")  \(outcome.check.title) — \(outcome.detail)")
        }
        lines.append("```")
        // Never send what the sharing commands would refuse to share.
        return Redact.apply(lines.joined(separator: "\n"))
    }

    /// A prefilled issue. GitHub truncates very long query strings and some browsers refuse them
    /// outright, so the URL carries the title and an instruction; the body itself goes on the
    /// clipboard, which has no length limit.
    public static func issueURL(summary: String) -> URL {
        let failing = summary
            .split(separator: "\n")
            .first { $0.hasPrefix("FAIL") }
            .map { String($0.dropFirst(6)).trimmingCharacters(in: .whitespaces) }
        var components = URLComponents(string: issuesURL)!
        components.queryItems = [
            URLQueryItem(name: "title", value: failing.map { "Problem: \($0)" } ?? "Problem report"),
            URLQueryItem(name: "body", value: "Paste the diagnostics from your clipboard here."),
        ]
        return components.url ?? URL(string: issuesURL)!
    }
}
