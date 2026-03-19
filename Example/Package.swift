// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "RichTextExample",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
    ],
    products: [
        .library(
            name: "RichTextExample",
            targets: ["RichTextExample"]
        ),
    ],
    dependencies: [
        .package(path: "../"), // RichText
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing.git", from: "1.19.0"),
    ],
    targets: [
        .target(
            name: "RichTextExample",
            dependencies: [
                "RichText",
            ]
        ),
        .testTarget(
            name: "RichTextUITesting",
            dependencies: [
                "RichTextExample",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
            ],
        ),
    ]
)
