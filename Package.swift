// swift-tools-version: 6.3.3

import PackageDescription

extension String {
    static let rfc6238: Self = "RFC 6238"
}

extension Target.Dependency {
    static var rfc6238: Self { .target(name: .rfc6238) }
}

let package = Package(
    name: "swift-rfc-6238",
    platforms: [
        .macOS("27"),
        .iOS("27"),
        .tvOS("27"),
        .watchOS("27")
    ],
    products: [
        .library(name: "RFC 6238", targets: ["RFC 6238"])
    ],
    dependencies: [
        .package(url: "https://github.com/swift-primitives/swift-dependency-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-ascii-primitives.git", branch: "main"),
    ],
    targets: [
        .target(
            name: "RFC 6238",
            dependencies: [
                .product(name: "Dependency Primitives", package: "swift-dependency-primitives"),
                .product(name: "ASCII Primitives", package: "swift-ascii-primitives"),
            ]
        ),
        .testTarget(
            name: "RFC 6238 Tests",
            dependencies: [
                "RFC 6238",
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)

extension String {
    var tests: Self { self + " Tests" }
    var foundation: Self { self + " Foundation" }
}

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    let ecosystem: [SwiftSetting] = [
        .strictMemorySafety(),
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        .enableExperimentalFeature("Lifetimes"),
        .enableExperimentalFeature("SuppressedAssociatedTypes"),
    ]

    let package: [SwiftSetting] = []

    target.swiftSettings = (target.swiftSettings ?? []) + ecosystem + package
}
