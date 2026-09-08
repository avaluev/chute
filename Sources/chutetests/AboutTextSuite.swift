import Foundation
import ChuteCore

func aboutTextSuite() {
    T.suite("AboutText") {
        let withBuild = AboutText.about(version: "0.2.1", build: "87c2cef")
        T.eq(withBuild.heading, "Chute 0.2.1", "the heading is the version")
        T.eq(withBuild.body.first, "build 87c2cef", "the build stamp is shown when the bundle has one")
        T.eq(withBuild.body.count, 2, "stamp and privacy, nothing else")

        let noBuild = AboutText.about(version: "0.2.1", build: nil)
        T.eq(noBuild.body.count, 1, "an unstamped bundle shows no stamp line rather than 'unknown'")
        T.eq(noBuild.body.first, AboutText.privacy, "and still says the privacy sentence")

        // THE CLAUSE THAT MAKES THE CLAIM HONEST. The privacy sentence is only true because it
        // names the one command that uploads and says whose credentials it uses. Drop that half
        // and it becomes the absolute claim the fact sheet forbids.
        T.ok(AboutText.privacy.contains("`chute gist`"), "the one command that uploads is named")
        T.ok(AboutText.privacy.contains("your own `gh`"), "and it says whose credentials it uses")
        T.ok(AboutText.privacy.contains("redacting keys and tokens"), "and what it strips first")
        T.ok(AboutText.privacy.contains("no telemetry"), "the three absences are still stated")
        T.no(AboutText.privacy.lowercased().contains("never uploads"),
             "no absolute upload claim survives — `gist` uploads")
    
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
