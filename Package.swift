// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "VideoPlayer",
    platforms: [.iOS(.v13)],
    products: [
        .library(
            name: "VideoPlayer",
            targets: ["VideoPlayer"]),
    ],
    targets: [
        .target(
            name: "VideoPlayer",
            path: "Sources"),
    ]
)
