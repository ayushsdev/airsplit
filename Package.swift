// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AirSplit",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [
        .package(url: "https://github.com/rnine/SimplyCoreAudio.git", branch: "develop")
    ],
    targets: [
        .executableTarget(
            name: "AirSplit",
            dependencies: ["SimplyCoreAudio"],
            path: "AirSplit",
            exclude: ["Resources/AirSplit.entitlements", "Info.plist"]
        )
    ]
)
