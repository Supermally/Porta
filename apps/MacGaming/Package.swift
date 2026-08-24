// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Porta",
    platforms: [
        .macOS("26.0")
    ],
    products: [
        .executable(
            name: "Porta",
            targets: ["Porta"]
        ),
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "Porta",
            dependencies: [],
            path: "Sources/MacGaming"
        ),
    ]
)
