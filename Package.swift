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
        // `exclude` because Sources/ChuteApp/LICENSE is the proprietary half of the open-core
        // split (the root LICENSE is MIT and says so), and SwiftPM warns about any file in a
        // target directory it has no rule for.
        .executableTarget(name: "ChuteApp", dependencies: ["ChuteCore"], exclude: ["LICENSE"]),
        // `fixtures/` is read at run time by path (AgentTranscriptSuite), not bundled.
        .executableTarget(name: "chutetests", dependencies: ["ChuteCore"], exclude: ["fixtures"]),
    ]
)
