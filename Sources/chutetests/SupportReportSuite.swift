import Foundation
import ChuteCore

func supportReportSuite() {
    T.suite("SupportReport") {
        let outcomes = [
            CheckOutcome(check: Diagnostics.all[0], passed: true, detail: "macOS 14"),
            CheckOutcome(check: Diagnostics.all[1], passed: false,
                         detail: "/Users/x/Downloads/Chute.app"),
        ]
        let report = SupportReport.build(outcomes: outcomes, version: "0.1.0", osVersion: "14.6.1",
                                         extras: ["finder extension": "never loaded"])

        T.ok(report.contains("PASS  macOS version"), "passing checks are included for context")
        T.ok(report.contains("FAIL  App location"), "and failures are marked as such")
        T.ok(report.contains("chute 0.1.0 · macOS 14.6.1"), "versions are stated")
        T.ok(report.contains("finder extension: never loaded"), "extras appear")
        T.ok(report.contains("What happened"), "the reporter is asked what they were doing")

        // A report is pasted in public. Anything the sharing commands would refuse to share, this
        // must refuse too — a check detail is a path, and a path can contain a token.
        let leaky = [CheckOutcome(check: Diagnostics.all[0], passed: false,
                                  detail: "failed with sk-ant-api03-SECRETVALUE1234567890")]
        let masked = SupportReport.build(outcomes: leaky, version: "0.1.0", osVersion: "14")
        T.ok(!masked.contains("SECRETVALUE"), "a key in a check detail never reaches the issue")
        T.ok(masked.contains("[REDACTED]"), "and its place is marked")

        // The issue link is prefilled but the body is not: a full report would blow the URL length.
        let url = SupportReport.issueURL(summary: report)
        T.ok(url.absoluteString.hasPrefix(SupportReport.issuesURL), "it points at the public tracker")
        T.ok(url.absoluteString.contains("title=Problem"), "the title names the failing check")
        T.ok(url.absoluteString.contains("clipboard"), "and the body says where the diagnostics are")
        T.ok(url.absoluteString.count < 2000, "short enough for every browser to accept")
        // URLComponents percent-encodes a space as %20, not +.
        T.ok(SupportReport.issueURL(summary: "no failures here").absoluteString.contains("Problem%20report"),
             "a report with nothing failing still opens a usable issue")
    }
}
