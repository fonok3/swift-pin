import PinPluginToolCore
import PinUtilities
import Testing

struct CodeGeneratorTests {
    // MARK: Nested Types

    struct ProvidingProtocol {
        @Test
        func generated() {
            let gen = CodeGenerator(
                components: [
                    ComponentInfo(
                        className: "FeatureComponent",
                        accessLevel: .public,
                        properties: [],
                        subcomponents: []
                    )
                ],
                imports: []
            )
            let output = gen.generate()
            #expect(output.contains("@MainActor public protocol FeatureComponentProviding {"))
            #expect(output.contains("var featureComponent: FeatureComponent { get }"))
        }

        @Test
        func inheritsSubcomponentProtocols() {
            let gen = CodeGenerator(
                components: [
                    ComponentInfo(
                        className: "AppComponent",
                        accessLevel: .internal,
                        properties: [],
                        subcomponents: [
                            SubcomponentInfo(propertyName: "feature", typeName: "FeatureComponent")
                        ]
                    )
                ],
                imports: []
            )
            let output = gen.generate()
            let expected =
                "@MainActor protocol AppComponentProviding: "
                + "FeatureComponentProviding, FeatureComponentDependency {"
            #expect(output.contains(expected))
        }

        @Test
        func inheritsMultipleSubcomponents() {
            let gen = CodeGenerator(
                components: [
                    ComponentInfo(
                        className: "AppComponent",
                        accessLevel: .public,
                        properties: [],
                        subcomponents: [
                            SubcomponentInfo(propertyName: "one", typeName: "OneComponent"),
                            SubcomponentInfo(propertyName: "two", typeName: "TwoComponent")
                        ]
                    )
                ],
                imports: []
            )
            let output = gen.generate()
            let expected =
                "public protocol AppComponentProviding: "
                + "OneComponentProviding, OneComponentDependency, "
                + "TwoComponentProviding, TwoComponentDependency {"
            #expect(output.contains(expected))
        }
    }

    struct ConformanceExtension {
        @Test
        func generated() {
            let gen = CodeGenerator(
                components: [
                    ComponentInfo(className: "MyComponent", accessLevel: .public, properties: [], subcomponents: [])
                ],
                imports: []
            )
            let output = gen.generate()
            #expect(output.contains("@MainActor extension MyComponent: MyComponentProviding {}"))
        }
    }

    struct SelfAccessor {
        @Test
        func generated() {
            let gen = CodeGenerator(
                components: [
                    ComponentInfo(
                        className: "FeatureComponent",
                        accessLevel: .public,
                        properties: [],
                        subcomponents: []
                    )
                ],
                imports: []
            )
            let output = gen.generate()
            #expect(output.contains("public var featureComponent: FeatureComponent { self }"))
        }

        @Test
        func internalOmitsAccessLevel() {
            let gen = CodeGenerator(
                components: [
                    ComponentInfo(
                        className: "FeatureComponent",
                        accessLevel: .internal,
                        properties: [],
                        subcomponents: []
                    )
                ],
                imports: []
            )
            let output = gen.generate()
            #expect(output.contains("    var featureComponent: FeatureComponent { self }"))
        }
    }

    struct ForwardingExtensions {
        @Test
        func generatedUnderscoredOnly() {
            let gen = CodeGenerator(
                components: [
                    ComponentInfo(
                        className: "FeatureOneComponent",
                        accessLevel: .public,
                        properties: [
                            PropertyInfo(name: "logger", type: "Logger"),
                            PropertyInfo(name: "analytics", type: "Analytics")
                        ],
                        subcomponents: []
                    )
                ],
                imports: []
            )
            let output = gen.generate()
            #expect(output.contains("@MainActor extension FeatureOneComponentProviding {"))
            #expect(output.contains("public var _logger: Logger { featureOneComponent.logger }"))
            #expect(output.contains("public var _analytics: Analytics { featureOneComponent.analytics }"))
            // Clean names should NOT be in the Providing forwarding
            #expect(!output.contains("public var logger: Logger"))
            #expect(!output.contains("public var analytics: Analytics"))
        }

        @Test
        func skippedWhenNoProperties() {
            let gen = CodeGenerator(
                components: [
                    ComponentInfo(className: "EmptyComponent", accessLevel: .public, properties: [], subcomponents: [])
                ],
                imports: []
            )
            let output = gen.generate()
            #expect(!output.contains("extension EmptyComponentProviding {"))
        }
    }

    struct SubcomponentAccessor {
        @Test
        func generatedOnProvidingProtocol() {
            let gen = CodeGenerator(
                components: [
                    ComponentInfo(
                        className: "AppComponent",
                        accessLevel: .internal,
                        properties: [],
                        subcomponents: [
                            SubcomponentInfo(propertyName: "myFeature", typeName: "FeatureComponent")
                        ]
                    )
                ],
                imports: []
            )
            let output = gen.generate()
            #expect(output.contains("extension AppComponentProviding {"))
            #expect(output.contains("var featureComponent: FeatureComponent { appComponent.myFeature }"))
        }

        @Test
        func generatedEvenWhenNamesMatch() {
            let gen = CodeGenerator(
                components: [
                    ComponentInfo(
                        className: "AppComponent",
                        accessLevel: .internal,
                        properties: [],
                        subcomponents: [
                            SubcomponentInfo(propertyName: "featureComponent", typeName: "FeatureComponent")
                        ]
                    )
                ],
                imports: []
            )
            let output = gen.generate()
            #expect(output.contains("var featureComponent: FeatureComponent { appComponent.featureComponent }"))
        }

        @Test
        func escapesKeywordPropertyName() {
            let gen = CodeGenerator(
                components: [
                    ComponentInfo(
                        className: "AppComponent",
                        accessLevel: .internal,
                        properties: [],
                        subcomponents: [
                            SubcomponentInfo(propertyName: "default", typeName: "DefaultComponent")
                        ]
                    )
                ],
                imports: []
            )
            let output = gen.generate()
            #expect(output.contains("var defaultComponent: DefaultComponent { appComponent.`default` }"))
        }
    }

    struct Imports {
        @Test
        func deduplicatedAndSorted() {
            let gen = CodeGenerator(
                components: [
                    ComponentInfo(className: "MyComponent", accessLevel: .internal, properties: [], subcomponents: [])
                ],
                imports: ["import Foundation", "import Pin", "import Foundation", "import AppKit"]
            )
            let output = gen.generate()
            #expect(output.contains("import AppKit"))
            #expect(output.contains("import Foundation"))
            #expect(output.contains("import Pin"))

            let foundationCount = output.split(separator: "import Foundation").count - 1
            #expect(foundationCount == 1)
        }
    }

    struct AccessLevelTests {
        @Test
        func packagePropagated() {
            let gen = CodeGenerator(
                components: [
                    ComponentInfo(
                        className: "MyComponent",
                        accessLevel: .package,
                        properties: [PropertyInfo(name: "value", type: "Int")],
                        subcomponents: []
                    )
                ],
                imports: []
            )
            let output = gen.generate()
            #expect(output.contains("@MainActor package protocol MyComponentProviding {"))
            #expect(output.contains("package var myComponent: MyComponent { self }"))
            #expect(output.contains("    package var _value: Int { myComponent.value }"))
        }
    }

    struct LowercasePrefixTests {
        @Test
        func singleUppercase() {
            #expect(lowercasePrefix("AppComponent") == "appComponent")
        }

        @Test
        func multipleUppercase() {
            #expect(lowercasePrefix("AFNetworkClient") == "afNetworkClient")
        }

        @Test
        func allUppercase() {
            #expect(lowercasePrefix("URL") == "url")
        }

        @Test
        func urlSession() {
            #expect(lowercasePrefix("URLSession") == "urlSession")
        }

        @Test
        func alreadyLowercase() {
            #expect(lowercasePrefix("already") == "already")
        }
    }

    struct FullOutput {
        @Test
        func simpleComponent() {
            let gen = CodeGenerator(
                components: [
                    ComponentInfo(
                        className: "FeatureOneComponent",
                        accessLevel: .public,
                        properties: [
                            PropertyInfo(name: "logger", type: "Logger")
                        ],
                        subcomponents: [],
                        dependencies: [
                            PropertyInfo(name: "logger", type: "Logger")
                        ]
                    )
                ],
                imports: ["import Pin"]
            )
            let expected = """
                // Auto-generated by PinPlugin. Do not edit.

                import Pin

                @MainActor public protocol FeatureOneComponentProviding {
                    var featureOneComponent: FeatureOneComponent { get }
                }

                @MainActor extension FeatureOneComponent: FeatureOneComponentProviding {}

                @MainActor extension FeatureOneComponent {
                    public var featureOneComponent: FeatureOneComponent { self }
                }

                @MainActor extension FeatureOneComponentProviding {
                    public var _logger: Logger { featureOneComponent.logger }
                }

                @MainActor extension FeatureOneComponentDependency {
                    public var logger: Logger { _logger }
                }

                """
            #expect(gen.generate() == expected)
        }

        @Test
        func parentWithSubcomponents() {
            let gen = CodeGenerator(
                components: [
                    ComponentInfo(
                        className: "AppComponent",
                        accessLevel: .internal,
                        properties: [
                            PropertyInfo(name: "config", type: "AppConfig")
                        ],
                        subcomponents: [
                            SubcomponentInfo(propertyName: "featureOne", typeName: "FeatureOneComponent"),
                            SubcomponentInfo(propertyName: "featureTwo", typeName: "FeatureTwoComponent")
                        ]
                    )
                ],
                imports: ["import FeatureOne", "import FeatureTwo"]
            )

            let expected = """
                // Auto-generated by PinPlugin. Do not edit.

                import FeatureOne
                import FeatureTwo

                @MainActor protocol AppComponentProviding: FeatureOneComponentProviding, FeatureOneComponentDependency, FeatureTwoComponentProviding, FeatureTwoComponentDependency {
                    var appComponent: AppComponent { get }
                }

                @MainActor extension AppComponent: AppComponentProviding {}

                @MainActor extension AppComponent {
                    var appComponent: AppComponent { self }
                }

                @MainActor extension AppComponentProviding {
                    var _config: AppConfig { appComponent.config }
                }

                @MainActor extension AppComponentProviding {
                    var featureOneComponent: FeatureOneComponent { appComponent.featureOne }
                    var featureTwoComponent: FeatureTwoComponent { appComponent.featureTwo }
                }

                """
            #expect(gen.generate() == expected)
        }
    }

    struct DependencyDefaultImpl {
        @Test
        func generatedForComponentWithDependencies() {
            let gen = CodeGenerator(
                components: [
                    ComponentInfo(
                        className: "FeatureComponent",
                        accessLevel: .public,
                        properties: [],
                        subcomponents: [],
                        dependencies: [
                            PropertyInfo(name: "logger", type: "Logger"),
                            PropertyInfo(name: "httpClient", type: "HTTPClient")
                        ]
                    )
                ],
                imports: []
            )
            let output = gen.generate()
            #expect(output.contains("@MainActor extension FeatureComponentDependency {"))
            #expect(output.contains("public var logger: Logger { _logger }"))
            #expect(output.contains("public var httpClient: HTTPClient { _httpClient }"))
        }

        @Test
        func skippedWhenNoDependencies() {
            let gen = CodeGenerator(
                components: [
                    ComponentInfo(className: "RootComponent", accessLevel: .internal, properties: [], subcomponents: [])
                ],
                imports: []
            )
            let output = gen.generate()
            #expect(!output.contains("RootComponentDependency"))
        }
    }

    struct UnownedConformance {
        @Test
        func generated() {
            let gen = CodeGenerator(
                components: [
                    ComponentInfo(
                        className: "CarPlayComponent",
                        accessLevel: .public,
                        properties: [],
                        subcomponents: [],
                        dependencies: [
                            PropertyInfo(name: "logger", type: "Logger")
                        ],
                        dependencySource: "AppComponent"
                    )
                ],
                imports: []
            )
            let output = gen.generate()
            #expect(output.contains("@MainActor extension AppComponent: CarPlayComponentDependency {}"))
        }

        @Test
        func skippedWhenNoFrom() {
            let gen = CodeGenerator(
                components: [
                    ComponentInfo(
                        className: "FeatureComponent",
                        accessLevel: .public,
                        properties: [],
                        subcomponents: [],
                        dependencies: [
                            PropertyInfo(name: "logger", type: "Logger")
                        ]
                    )
                ],
                imports: []
            )
            let output = gen.generate()
            #expect(!output.contains("extension AppComponent:"))
        }

        @Test
        func fullOutputWithFrom() {
            let gen = CodeGenerator(
                components: [
                    ComponentInfo(
                        className: "CarPlayComponent",
                        accessLevel: .public,
                        properties: [
                            PropertyInfo(name: "dashboard", type: "Dashboard")
                        ],
                        subcomponents: [],
                        dependencies: [
                            PropertyInfo(name: "logger", type: "Logger")
                        ],
                        dependencySource: "AppComponent"
                    )
                ],
                imports: ["import Pin"]
            )
            let expected = """
                // Auto-generated by PinPlugin. Do not edit.

                import Pin

                @MainActor public protocol CarPlayComponentProviding {
                    var carPlayComponent: CarPlayComponent { get }
                }

                @MainActor extension CarPlayComponent: CarPlayComponentProviding {}

                @MainActor extension CarPlayComponent {
                    public var carPlayComponent: CarPlayComponent { self }
                }

                @MainActor extension CarPlayComponentProviding {
                    public var _dashboard: Dashboard { carPlayComponent.dashboard }
                }

                @MainActor extension CarPlayComponentDependency {
                    public var logger: Logger { _logger }
                }

                @MainActor extension AppComponent: CarPlayComponentDependency {}

                """
            #expect(gen.generate() == expected)
        }
    }

    struct InternalProviding {
        @Test
        func generatedWhenInternalPropertiesExist() {
            let gen = CodeGenerator(
                components: [
                    ComponentInfo(
                        className: "ParentComponent",
                        accessLevel: .public,
                        properties: [
                            PropertyInfo(name: "api", type: "API")
                        ],
                        internalProperties: [
                            PropertyInfo(name: "config", type: "AppConfig")
                        ],
                        subcomponents: []
                    )
                ],
                imports: []
            )
            let output = gen.generate()
            // Public Providing protocol
            #expect(output.contains("@MainActor public protocol ParentComponentProviding {"))
            // Internal InternalProviding protocol inherits public one
            #expect(
                output.contains(
                    "@MainActor protocol ParentComponentInternalProviding: ParentComponentProviding {"
                )
            )
            // Conformance uses InternalProviding
            #expect(
                output.contains(
                    "extension ParentComponent: ParentComponentInternalProviding {}"
                )
            )
            // Public forwarding on Providing
            #expect(output.contains("public var _api: API { parentComponent.api }"))
            // Internal forwarding on InternalProviding
            #expect(output.contains("extension ParentComponentInternalProviding {"))
            #expect(output.contains("    var _config: AppConfig { parentComponent.config }"))
        }

        @Test
        func skippedWhenNoInternalProperties() {
            let gen = CodeGenerator(
                components: [
                    ComponentInfo(
                        className: "FeatureComponent",
                        accessLevel: .public,
                        properties: [PropertyInfo(name: "logger", type: "Logger")],
                        subcomponents: []
                    )
                ],
                imports: []
            )
            let output = gen.generate()
            #expect(!output.contains("InternalProviding"))
            #expect(output.contains("extension FeatureComponent: FeatureComponentProviding {}"))
        }

        @Test
        func fullOutputWithInternalProperties() {
            let gen = CodeGenerator(
                components: [
                    ComponentInfo(
                        className: "ParentComponent",
                        accessLevel: .public,
                        properties: [
                            PropertyInfo(name: "api", type: "API")
                        ],
                        internalProperties: [
                            PropertyInfo(name: "config", type: "AppConfig"),
                            PropertyInfo(name: "cache", type: "Cache")
                        ],
                        subcomponents: [
                            SubcomponentInfo(propertyName: "child", typeName: "ChildComponent")
                        ]
                    )
                ],
                imports: ["import Pin"]
            )
            let expected = """
                // Auto-generated by PinPlugin. Do not edit.

                import Pin

                @MainActor public protocol ParentComponentProviding: ChildComponentProviding, ChildComponentDependency {
                    var parentComponent: ParentComponent { get }
                }

                @MainActor protocol ParentComponentInternalProviding: ParentComponentProviding {
                }

                @MainActor extension ParentComponent: ParentComponentInternalProviding {}

                @MainActor extension ParentComponent {
                    public var parentComponent: ParentComponent { self }
                }

                @MainActor extension ParentComponentProviding {
                    public var _api: API { parentComponent.api }
                }

                @MainActor extension ParentComponentInternalProviding {
                    var _config: AppConfig { parentComponent.config }
                    var _cache: Cache { parentComponent.cache }
                }

                @MainActor extension ParentComponentProviding {
                    public var childComponent: ChildComponent { parentComponent.child }
                }

                """
            #expect(gen.generate() == expected)
        }
    }

    struct CycleDetection {
        @Test
        func detectsDirectCycle() {
            let gen = CodeGenerator(
                components: [
                    ComponentInfo(
                        className: "AComponent",
                        accessLevel: .internal,
                        properties: [],
                        subcomponents: [SubcomponentInfo(propertyName: "b", typeName: "BComponent")]
                    ),
                    ComponentInfo(
                        className: "BComponent",
                        accessLevel: .internal,
                        properties: [],
                        subcomponents: [SubcomponentInfo(propertyName: "a", typeName: "AComponent")]
                    )
                ],
                imports: []
            )
            let errors = gen.detectCycles()
            #expect(errors.count == 1)
            #expect(errors[0].contains("AComponent"))
            #expect(errors[0].contains("BComponent"))
        }

        @Test
        func detectsTransitiveCycle() {
            let gen = CodeGenerator(
                components: [
                    ComponentInfo(
                        className: "AComponent",
                        accessLevel: .internal,
                        properties: [],
                        subcomponents: [SubcomponentInfo(propertyName: "b", typeName: "BComponent")]
                    ),
                    ComponentInfo(
                        className: "BComponent",
                        accessLevel: .internal,
                        properties: [],
                        subcomponents: [SubcomponentInfo(propertyName: "c", typeName: "CComponent")]
                    ),
                    ComponentInfo(
                        className: "CComponent",
                        accessLevel: .internal,
                        properties: [],
                        subcomponents: [SubcomponentInfo(propertyName: "a", typeName: "AComponent")]
                    )
                ],
                imports: []
            )
            let errors = gen.detectCycles()
            #expect(errors.count == 1)
            #expect(errors[0].contains("AComponent → BComponent → CComponent → AComponent"))
        }

        @Test
        func noCycleReturnsEmpty() {
            let gen = CodeGenerator(
                components: [
                    ComponentInfo(
                        className: "AppComponent",
                        accessLevel: .internal,
                        properties: [],
                        subcomponents: [SubcomponentInfo(propertyName: "feature", typeName: "FeatureComponent")]
                    ),
                    ComponentInfo(
                        className: "FeatureComponent",
                        accessLevel: .internal,
                        properties: [],
                        subcomponents: []
                    )
                ],
                imports: []
            )
            #expect(gen.detectCycles().isEmpty)
        }
    }

    // MARK: Functions

    @Test
    func noComponentsGeneratesPlaceholder() {
        let gen = CodeGenerator(components: [], imports: [])
        #expect(gen.generate() == "// No @PinComponent classes found in this target.\n")
    }
}
