// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AgentDashboard",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "AgentDashboard",
            targets: ["AgentDashboard"]),
    ],
    dependencies: [
        // The Composable Architecture
        .package(
            url: "https://github.com/pointfreeco/swift-composable-architecture",
            from: "1.13.0"
        ),
        // SwiftTerm for terminal emulation
        .package(
            url: "https://github.com/migueldeicaza/SwiftTerm",
            from: "1.2.0"
        ),
        // Swift Charts (included in iOS 16+)
    ],
    targets: [
        .target(
            name: "AgentDashboard",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "SwiftTerm", package: "SwiftTerm")
            ],
            path: "AgentDashboard"),
        .testTarget(
            name: "AgentDashboardTests",
            dependencies: ["AgentDashboard"],
            path: "AgentDashboardTests"),
    ]
)