// swift-tools-version:5.10
import PackageDescription

// ponytail: zero external dependencies on purpose — `swift build` stays offline and instant.
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
        .testTarget(name: "ChuteCoreTests", dependencies: ["ChuteCore"]),
    ]
)
