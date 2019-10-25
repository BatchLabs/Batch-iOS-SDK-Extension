// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BatchExtension",
    platforms: [
        .iOS(.v10)
    ],
    products: [
        .library(
            name: "BatchExtension",
            targets: ["BatchExtension"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "BatchExtension",
            dependencies: [],
            path: "Sources/Swift",
            swiftSettings: [.define("BATCHEXTENSION_PURE_SWIFT")]
            ),
    ]
)
