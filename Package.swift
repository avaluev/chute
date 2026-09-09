// swift-tools-version:5.10
import PackageDescription

// ponytail: zero external dependencies — `swift build` stays offline and instant.
// XCTest is unavailable on a Command-Line-Tools-only toolchain, so the suite is a plain
// executable (`swift run chutetests`) with an assert harness instead of a .testTarget.
let package = Package(
    name: "Chute",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "chute", targets: ["chute"]),
        .library(name: "ChuteCore", targets: ["ChuteCore"]),
    ],
    targets: [
        .target(name: "ChuteCore"),
        .executableTarget(name: "chute", dependencies: ["ChuteCore"]),
        .executableTarget(name: "ChuteApp", dependencies: ["ChuteCore"]),
        // `fixtures/` is read at run time by path (AgentTranscriptSuite), not bundled.
        .executableTarget(name: "chutetests", dependencies: ["ChuteCore"], exclude: ["fixtures"]),
        // The hot-path benchmark — see docs/specs/PERFORMANCE.md. Lives at Scripts/bench.swift,
        // not Sources/bench/, so it sits beside the other one-off tools in Scripts/ rather than
        // reading as a fifth product; `path`+`sources` point SwiftPM at it without moving it.
        // EVERYTHING ELSE IN Scripts/ IS EXCLUDED, explicitly and by name: without this,
        // `swift build` prints a 26-line "unhandled files" warning on EVERY build, forever,
        // because it treats the whole directory as this target's source tree. A new file dropped
        // into Scripts/ later brings the warning back for itself — that is the honest cost of
        // sharing a folder with tools this target does not own, not a bug in this list.
        .executableTarget(name: "bench", dependencies: ["ChuteCore"], path: "Scripts",
                          exclude: ["acceptance.sh", "build-app.sh", "check-focus.sh",
                                    "check-metrics.sh", "check-untested-logic.sh",
                                    "cloudflare-setup.sh", "deploy-site.sh", "fixtures.sh",
                                    "focus-baseline.txt", "get.sh", "install.sh", "make-icon.swift",
                                    "marketing-board.swift", "marketing-gallery.swift",
                                    "menu-shot.swift", "notarize-setup.md", "package-dmg.sh",
                                    "preflight-recording.sh", "reinstall-if-stale.sh", "release.sh",
                                    "screens.sh", "sign-identity.sh", "smoke.sh", "uninstall.sh",
                                    "untested-logic.txt", "bench.sh"],
                          sources: ["bench.swift"]),
    ]
)
