// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "apple-calendar-cli",
    platforms: [.macOS(.v14)],
    products: [.executable(name: "acal", targets: ["acal"])],
    dependencies: [.package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0")],
    targets: [
        .executableTarget(
            name: "acal",
            dependencies: [.product(name: "ArgumentParser", package: "swift-argument-parser")]
        )
    ]
)
