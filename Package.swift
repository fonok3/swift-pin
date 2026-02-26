// swift-tools-version: 5.10

import CompilerPluginSupport
import PackageDescription

let package = Package(
    name: "swift-pin",
    platforms: [.macOS(.v10_15), .iOS(.v13), .tvOS(.v13), .watchOS(.v6), .macCatalyst(.v13), .visionOS(.v1)],
    products: [
        .library(
            name: "Pin",
            targets: ["Pin"]
        ),
        .plugin(
            name: "PinPlugin",
            targets: ["PinPlugin"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "602.0.0")
    ],
    targets: [
        // Pin is the only target that ships into user apps. It contains only
        // macro declarations and the PinDependency struct — no runtime code.
        // Its dependency on PinMacros is a .macro target, which SPM runs as a
        // compiler plugin process. PinMacros' dependencies (PinUtilities,
        // SwiftSyntax, etc.) do NOT link into the user's app binary.
        .target(
            name: "Pin",
            dependencies: ["PinMacros"]
        ),
        // Shared helpers used by PinMacros and PinPluginTool. Depends on
        // SwiftSyntax, but this is safe — all consumers are compile-time only
        // (macro plugin + build tool). SwiftSyntax never reaches user apps.
        .target(
            name: "PinUtilities",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftDiagnostics", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax")
            ]
        ),
        .macro(
            name: "PinMacros",
            dependencies: [
                "PinUtilities",
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
                .product(name: "SwiftSyntaxBuilder", package: "swift-syntax")
            ]
        ),
        .target(
            name: "PinPluginToolCore",
            dependencies: [
                "PinUtilities",
                .product(name: "SwiftSyntax", package: "swift-syntax")
            ]
        ),
        .executableTarget(
            name: "PinPluginTool",
            dependencies: [
                "PinPluginToolCore",
                .product(name: "SwiftParser", package: "swift-syntax")
            ]
        ),
        .plugin(
            name: "PinPlugin",
            capability: .buildTool(),
            dependencies: ["PinPluginTool"]
        ),
        .testTarget(
            name: "PinTests",
            dependencies: [
                "Pin",
                "PinMacros",
                "PinPluginToolCore",
                "PinUtilities",
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacroExpansion", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax"),
                .product(name: "SwiftParserDiagnostics", package: "swift-syntax"),
                .product(name: "SwiftBasicFormat", package: "swift-syntax")
            ]
        ),
        // Integration tests that compile real components with the macro and
        // build tool plugin, catching expansion bugs that string-based
        // assertMacroExpansion tests cannot.
        .testTarget(
            name: "PinIntegrationTests",
            dependencies: ["Pin"],
            plugins: [.plugin(name: "PinPlugin")]
        )
    ]
)
