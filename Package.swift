// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "holdit",
    platforms: [
        .macOS(.v15)
    ],
    targets: [
        .executableTarget(
            name: "holdit",
            path: "Sources",
            sources: [
                "main.swift",
                "Tray.swift"
            ]
        ),
    ]
)
