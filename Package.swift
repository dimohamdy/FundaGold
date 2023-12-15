// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FundaGold",
    platforms: [
        .macOS(.v10_15)
    ],
    dependencies: [
        .package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.6.0"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0")
    ],
    targets: [
        .executableTarget(
            name: "FundaGold",
            dependencies: ["SwiftSoup",
                           .product(name: "Logging", package: "swift-log") // Add Logging to dependencies
            ],
            resources: [
                .process("Resources/netherlands_cities.json")
            ]
        )
    ]
)
