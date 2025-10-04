// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "RichText",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
    ],
    products: [
        .library(
            name: "RichText",
            targets: ["RichText"]
        ),
    ],
    targets: [
        .target(
            name: "RichText"
        ),
    ]
)
