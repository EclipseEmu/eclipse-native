// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DummyCore",
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "DummyCore",
            type: .dynamic,
            targets: ["DummyCore"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/eclipseemu/eclipsekit.git", branch: "main"),
    ],
    targets: [
        .target(
            name: "DummyCore",
            dependencies: [.product(name: "EclipseKit", package: "eclipsekit")],
            linkerSettings: [.unsafeFlags(["-fprofile-instr-generate"])]
        ),
    ]
)
