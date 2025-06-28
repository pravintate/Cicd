// swift-tools-version: 5.10.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DIEngine",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        .library(
            name: "DIEngine",
            targets: ["DIEngine"])
    ],
    targets: [
        .target(
            name: "DIEngine"),
        .testTarget(
            name: "DIEngineTests",
            dependencies: ["DIEngine"]
        )
    ]
)
