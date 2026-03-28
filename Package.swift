// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "TinySQL",
    platforms: [.macOS(.v26)],
    dependencies: [
        .package(path: "Packages/TinyKit"),
        .package(url: "https://github.com/vapor/postgres-nio.git", from: "1.21.0"),
    ],
    targets: [
        .executableTarget(
            name: "TinySQL",
            dependencies: [
                "TinyKit",
                .product(name: "PostgresNIO", package: "postgres-nio"),
            ],
            path: "Sources/TinySQL",
            exclude: ["Resources"],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
    ]
)
