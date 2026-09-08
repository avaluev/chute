import Foundation
import ChuteCore

func aboutTextSuite() {
    T.suite("AboutText") {
        let withBuild = AboutText.about(version: "0.2.1", build: "87c2cef")
        T.eq(withBuild.heading, "Chute 0.2.1", "the heading is the version")
        T.eq(withBuild.body.first?.text, "build 87c2cef",
             "the build stamp is shown when the bundle has one")
        T.ok(withBuild.body.first?.heading == nil,
             "and carries no heading — it belongs to the version line, not a section of its own")
        T.eq(withBuild.body.count, 4, "stamp, why, privacy, star reason — nothing else")

        let noBuild = AboutText.about(version: "0.2.1", build: nil)
        T.eq(noBuild.body.count, 3, "an unstamped bundle shows no stamp line rather than 'unknown'")
        T.eq(noBuild.body.first?.text, AboutText.why,
             "and still opens with the first-person why, before privacy")
        T.ok(noBuild.body.contains { $0.text == AboutText.privacy },
             "and still says the privacy sentence")
        T.ok(noBuild.body.contains { $0.text == AboutText.starReason },
             "and still makes the one ask")

        // EVERY SECTION BUT THE BUILD STAMP IS FINDABLE BY ITS HEADING. Rendered flat, the tab was
        // five grey paragraphs and the ask read as a sixth — see `Section` for why that changed.
        T.eq(noBuild.body.map { $0.heading ?? "" },
             [AboutText.whyHeading, AboutText.privacyHeading, AboutText.starHeading],
             "each section is titled, in order: why, then what it does with your data, then the ask")
        T.no(AboutText.starHeading.lowercased().contains("support"),
             "the ask's heading states a condition, never assumes the answer")

        // THE CLAUSE THAT MAKES THE CLAIM HONEST. The privacy sentence is only true because it
        // names the one command that uploads and says whose credentials it uses. Drop that half
        // and it becomes the absolute claim the fact sheet forbids.
        T.ok(AboutText.privacy.contains("`chute gist`"), "the one command that uploads is named")
        T.ok(AboutText.privacy.contains("your own `gh`"), "and it says whose credentials it uses")
        T.ok(AboutText.privacy.contains("redacting keys and tokens"), "and what it strips first")
        T.ok(AboutText.privacy.contains("no telemetry"), "the three absences are still stated")

        // THE SWEEP COVERS EVERY NEW SENTENCE IN THE TAB, NOT JUST `privacy` — an absolute upload
        // claim would be just as false coming from `why` or `starReason` as it was from the old
        // sentence this suite was written to catch.
        let allAboutProse = [AboutText.why, AboutText.privacy, AboutText.starReason, AboutText.starTitle]
            .joined(separator: " ")
        T.no(allAboutProse.lowercased().contains("never uploads"),
             "no absolute upload claim survives anywhere in the About tab — `gist` uploads")

        // ── THE FIRST-PERSON OPENING ────────────────────────────────────────────────────────
        T.ok(!AboutText.why.isEmpty, "the opening exists")
        T.ok(AboutText.why.lowercased().contains("i "), "written in first person, by the author")

        // ── THE STAR CTA ─────────────────────────────────────────────────────────────────────
        T.eq(AboutText.starURL.scheme, "https", "the star URL parses and is https")
        T.eq(AboutText.starURL.host, "github.com", "and points at GitHub")
        T.ok(AboutText.starReason.lowercased().contains("telemetry")
             && AboutText.starReason.lowercased().contains("signal"),
             "the CTA copy names its reason, not a plea")
        T.ok(!AboutText.starTitle.isEmpty, "the button has a title")

        // ── THE CONTACT ROWS ────────────────────────────────────────────────────────────────
        T.eq(AboutText.contacts.count, 3, "three ways to reach a human")
        for c in AboutText.contacts {
            T.ok(!c.label.isEmpty, "\(c.label): has a label")
            T.ok(!c.handle.isEmpty, "\(c.label): shows a handle, not a bare URL")
            T.ok(URL(string: c.url) != nil, "\(c.label): the URL parses")
            T.ok(c.url.hasPrefix("https://"),
                 "\(c.label): https — never a plain http link out of a shipped app")
        }
        T.ok(AboutText.contacts.contains { $0.label == "GitHub" }, "GitHub is there")
        T.ok(AboutText.contacts.contains { $0.label == "LinkedIn" }, "LinkedIn is there")
        T.ok(AboutText.contacts.contains { $0.label == "Telegram" }, "and Telegram")

        // NO PHONE NUMBER, EVER. A handle can be abandoned; a number cannot be un-scraped once a
        // bot has it, and this ships to strangers. The same rule took the founder's home address
        // off the website on 2026-09-08 — it must not walk back in through the About tab. Assert
        // on the shape of a number rather than on one specific number, or the guard only catches
        // the mistake nobody was going to make twice.
        let joined = AboutText.contacts.map { $0.handle + " " + $0.url }.joined(separator: " ")
        T.no(joined.contains("tel:"), "no tel: link")
        T.no(joined.contains("wa.me"), "no WhatsApp link — that publishes a mobile number")
        let digitRun = joined.reduce(into: (best: 0, run: 0)) { acc, ch in
            acc.run = ch.isNumber ? acc.run + 1 : 0
            acc.best = max(acc.best, acc.run)
        }.best
        T.ok(digitRun < 7, "and no run of digits long enough to be a phone number (was \(digitRun))")
}
}
