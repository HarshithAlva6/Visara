// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Visara",
    defaultLocalization: "en",
    platforms: [
        // Minimum iOS 16 for broad device support
        // Foundation Models (on-device AI) requires iOS 26 — handled at runtime
        .iOS(.v16)
    ],
    products: [
        // The library product — what developers import
        .library(
            name: "Visara",
            targets: ["Visara"]
        )
    ],
    targets: [
        // Main library target
        // sources tells SPM exactly which root folders contain Swift files
        // This replaces the conventional Sources/ModuleName/ structure
        .target(
            name: "Visara",
            path: ".",
            exclude: ["ios", "bridge", "node_modules", ".github", "example"],
            sources: ["scanner", "providers", "models"]
        ),
        // Test target
        .testTarget(
            name: "VisaraTests",
            dependencies: ["Visara"],
            path: "tests"
        )
    ]
)
