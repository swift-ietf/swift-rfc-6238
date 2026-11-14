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
            url: "https://github.com/swift-ietf/swift-rfc-4226.git",
            branch: "main"
        )
    ],
    targets: [
        .target(
            name: "RFC 6238",
            dependencies: [
                .product(name: "RFC 4226", package: "swift-rfc-4226")
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
    target.swiftSettings =
        (target.swiftSettings ?? []) + [
            .strictMemorySafety(),
            .enableUpcomingFeature("ExistentialAny"),
            .enableUpcomingFeature("InternalImportsByDefault"),
            .enableUpcomingFeature("MemberImportVisibility"),
            .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
            .enableUpcomingFeature("InferIsolatedConformances"),
            .enableExperimentalFeature("Lifetimes"),
            .treatAllWarnings(as: .error),
        ]
}
