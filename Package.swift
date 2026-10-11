// swift-tools-version: 6.4

import PackageDescription

let package = Package(
    name: "swift-rfc-6238",
    platforms: [
        .macOS(.v27),
        .iOS(.v27),
        .tvOS(.v27),
        .watchOS(.v27),
        .visionOS(.v27),
    ],
    products: [
        .library(name: "RFC 6238", targets: ["RFC 6238"])
    ],
    dependencies: [
        .package(
            url: "https://github.com/swift-atoms/swift-dependency.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-atoms/swift-ascii.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-atoms/swift-byte.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-standards/swift-fips-180-4.git",
            branch: "main"
        ),
    ],
    targets: [
        .target(
            name: "RFC 6238",
            dependencies: [
                .product(name: "Dependency", package: "swift-dependency"),
                .product(name: "ASCII", package: "swift-ascii"),
                .product(name: "Byte", package: "swift-byte"),
                .product(name: "FIPS 180-4", package: "swift-fips-180-4"),
            ]
        ),
        .testTarget(
            name: "RFC 6238 Tests",
            dependencies: [
                .target(name: "RFC 6238")
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    let ecosystem: [SwiftSetting] = [
        .strictMemorySafety(),
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        .enableExperimentalFeature("Lifetimes"),
    ]

    let package: [SwiftSetting] = []

    target.swiftSettings = (target.swiftSettings ?? []) + ecosystem + package
}
