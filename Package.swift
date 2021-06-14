// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Deck",
    platforms: [.iOS(.v14)],
    products: [
        .library(
            name: "Deck",
            targets: ["Deck"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "Deck",
            dependencies: []),
        .testTarget(
            name: "DeckTests",
            dependencies: ["Deck"]),
    ]
)
