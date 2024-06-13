// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "HistyCore",
    platforms: [
        // Add support for all platforms starting from a specific version.
        .macOS(.v13),
        .iOS(.v13),
        .watchOS(.v9),
        .tvOS(.v16)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "HistyCore",
            targets: ["HistyCore"]),
    ],
    dependencies: [
        .package(url: "https://github.com/amplitude/Amplitude-iOS", branch: "main"),
        .package(url: "https://github.com/bizz84/SwiftyStoreKit", from: "0.16.4")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "HistyCore"),
        .testTarget(
            name: "HistyCoreTests",
            dependencies: ["HistyCore"]),
    ]
)
