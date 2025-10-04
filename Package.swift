// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "RichText",
    platforms: [
        .macOS(.v15),
        .iOS(.v18),
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
