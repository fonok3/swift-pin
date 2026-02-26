// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "swift-pin-example",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(path: "../")
    ],
    targets: [
        .target(
            name: "FeatureOne",
            dependencies: [.product(name: "Pin", package: "swift-pin")],
            plugins: [.plugin(name: "PinPlugin", package: "swift-pin")]
        ),
        .target(
            name: "FeatureTwo",
            dependencies: [
                "FeatureOne",
                .product(name: "Pin", package: "swift-pin")
            ],
            plugins: [.plugin(name: "PinPlugin", package: "swift-pin")]
        ),
        .executableTarget(
            name: "ExampleApp",
            dependencies: [
                "FeatureOne",
                "FeatureTwo",
                .product(name: "Pin", package: "swift-pin")
            ],
            plugins: [.plugin(name: "PinPlugin", package: "swift-pin")]
        )
    ],
    swiftLanguageModes: [.v6]
)
