// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "VibeWatch",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "VibeWatch",
            targets: ["VibeWatch"]
        )
    ],
    dependencies: [
        // Add GRDB for SQLite support
        .package(url: "https://github.com/groue/GRDB.swift.git", from: "6.0.0")
    ],
    targets: [
        .executableTarget(
            name: "VibeWatch",
            dependencies: [
                .product(name: "GRDB", package: "GRDB.swift")
            ],
            path: "Sources/VibeWatch",
            exclude: [
                "Info.plist"
            ]
        ),
        .testTarget(
            name: "VibeWatchTests",
            dependencies: ["VibeWatch"],
            path: "Tests/VibeWatchTests"
        )
    ]
)
