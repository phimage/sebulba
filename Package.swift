// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription

let package = Package(
    name: "sebulba",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .executable(
            name: "sebulba",
            targets: ["sebulba"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.0"),
        .package(url: "https://github.com/phimage/XcodeProjKit.git", from: "3.0.5")
    ],
    targets: [
        .executableTarget(
            name: "sebulba",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                "XcodeProjKit"],
            path: "Sources/main"
        )
    ]
)
