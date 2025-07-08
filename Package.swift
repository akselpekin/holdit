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
            dependencies: ["LOGIC"],
            path: "Sources/GUI"
        ),
        .target(
            name: "LOGIC",
            path: "Sources/LOGIC"
        ),
        .executableTarget(
            name: "main",
            dependencies: ["GUI", "LOGIC"],
            path: "Sources/holdit"
        ),
    ]
)
