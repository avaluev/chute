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
    }
}
