// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "AucorsaKit",
    // iOS is the shipping platform. watchOS is listed because the package is
    // UI-free so a future watch app can depend on it unchanged,
    // and macOS so `swift test` runs on the host
    // without booting a simulator.
    platforms: [.iOS(.v16), .watchOS(.v10), .macOS(.v13)],
    products: [
        .library(name: "AucorsaKit", targets: ["AucorsaKit"])
    ],
    targets: [
        .target(
            name: "AucorsaKit",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "AucorsaKitTests",
            dependencies: ["AucorsaKit"],
            resources: [.process("Fixtures")]
        )
    ]
)
