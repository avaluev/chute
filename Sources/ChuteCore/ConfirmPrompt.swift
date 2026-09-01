import Foundation

/// WHAT THE CONFIRMATION SHEET SAYS, decided without a screen.
///
/// This is the last text a user reads before files on disk change. Until 2026-09-01 it was
/// assembled inline inside an `NSAlert` call in `ChuteApp/RequestInbox.swift`, which is in a
/// target no test can import — 16 decision points, zero coverage, on the one surface where being
/// wrong destroys the user's work. Same move as `StatusMenu`: the decision is pure data, and only
/// the window needs AppKit.
public struct ConfirmPrompt: Equatable {
    /// The alert's `messageText` — the action and how much it is about to touch.
    public let title: String
    /// The alert's `informativeText` — the dry run, truncated to something a person can read.
    public let body: String
    /// How many items the dry run listed. Zero means the action found nothing to do.
    public let itemCount: Int

    /// How many rows of the dry run are shown before the rest is summarised. A Finder selection
    /// can be thousands of files, and an alert that tall is neither readable nor dismissable.
    public static let previewLineLimit = 15

    /// `preview` is the dry run's stdout: one item per line.
    public init(actionTitle: String, preview: String, limit: Int = ConfirmPrompt.previewLineLimit) {
        let lines = preview.split(separator: "\n", omittingEmptySubsequences: true)
        let shown = lines.prefix(max(0, limit)).map { $0.trimmingCharacters(in: .whitespaces) }
        let hidden = lines.count - shown.count
        var text = shown.joined(separator: "\n")
        if hidden > 0 { text += "\n… and \(hidden) more" }
        // An empty dry run must never render as an empty sheet. A blank body is how a user ends
        // up clicking "Move to Trash" on a list they could not see.
        if text.isEmpty { text = "Nothing to change here." }
        self.title = "\(actionTitle) — \(lines.count) item(s)"
        self.body = text
        self.itemCount = lines.count
    }
}
