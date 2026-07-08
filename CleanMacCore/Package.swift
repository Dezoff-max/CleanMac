// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CleanMacCore",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "CleanMacCore", targets: ["CleanMacCore"])
    ],
    targets: [
        .target(name: "CleanMacCore"),
        .testTarget(name: "CleanMacCoreTests", dependencies: ["CleanMacCore"]),
    ]
)
