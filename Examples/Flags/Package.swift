// swift-tools-version: 5.6

import PackageDescription

let package = Package(
    name: "Flags",
    platforms: [
        .macOS(.v12)
    ],
    dependencies: [
        .package(path: "../../")
    ],
    targets: [
        .executableTarget(
            name: "Flags",
            dependencies: ["SwiftTUI"]),
        .testTarget(
            name: "FlagsTests",
            dependencies: ["Flags"]),
    ]
)
