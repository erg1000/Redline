// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Redline",
    platforms: [.macOS(.v15)],
    targets: [
        .executableTarget(name: "Redline", path: "Sources/Redline"),
    ]
)
