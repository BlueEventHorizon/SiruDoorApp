// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SiruDoorModule",
    defaultLocalization: "ja",
    platforms: [
        .iOS(.v16),
    ],
    products: [
        .library(name: "AppModule", targets: ["AppModule"]),
        .library(name: "Domain", targets: ["Domain"]),
        .library(name: "Infrastructure", targets: ["Infrastructure"]),
    ],
    dependencies: [
        .package(url: "https://github.com/BlueEventHorizon/BwNearPeer", branch: "main"),
        .package(url: "https://github.com/BlueEventHorizon/BwLogger", from: "5.0.0"),
        .package(url: "https://github.com/SwiftGen/SwiftGenPlugin", from: "6.6.0"),
    ],
    targets: [
        .target(
            name: "AppModule",
            dependencies: [
                "Infrastructure",
                "Domain",
                "BwLogger",
            ],
            resources: [
                .process("Resources"),
            ],
            plugins: [
              .plugin(name: "SwiftGenPlugin", package: "SwiftGenPlugin")
            ]
        ),
        .target(
            name: "Domain",
            dependencies: [
                "Infrastructure",
                "BwNearPeer",
            ]
        ),
        .target(
            name: "Infrastructure",
            dependencies: []
        ),
        .testTarget(
            name: "DomainTests",
            dependencies: [
                "SiruDoorModule",
            ]
        ),
        .testTarget(
            name: "InfrastructureTests",
            dependencies: [
                "SiruDoorModule",
            ]
        ),
    ]
)
