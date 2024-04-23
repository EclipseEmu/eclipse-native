// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "EclipseKit",
    products: [
        .library(name: "EclipseKit", targets: ["EclipseKit"]),
    ],
    targets: [
        .target(name: "EclipseKit", linkerSettings: [.unsafeFlags(["-fprofile-instr-generate"])]),
    ]
)
