// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "holdit",
    platforms: [
        .macOS(.v15)
    ],
    targets: [
        .target(
            name: "GUI",
            path: "Sources/GUI"
        ),
        .executableTarget(
            name: "main",
            dependencies: ["GUI"],
            path: "Sources/holdit"
        ),
    ]
)
