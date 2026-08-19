// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MacGaming",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "MacGaming",
            targets: ["MacGaming"]
        ),
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "MacGaming",
            dependencies: [],
            path: "Sources/MacGaming"
        ),
    ]
)
