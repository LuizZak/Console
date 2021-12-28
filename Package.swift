// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "Console",
    products: [
        .library(
            name: "Console",
            targets: ["Console"]
        ),
        .library(
            name: "ConsoleTestHelpers",
            targets: ["ConsoleTestHelpers"]
        ),
    ],
    targets: [
        .target(
            name: "Console",
            dependencies: []
        ),
        .target(
            name: "ConsoleTestHelpers",
            dependencies: ["Console"]
        ),
        .testTarget(
            name: "ConsoleTests",
            dependencies: ["Console", "ConsoleTestHelpers"]
        ),
    ],
    swiftLanguageVersions: [.v5]
)
