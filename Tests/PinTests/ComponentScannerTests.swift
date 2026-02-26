import PinPluginToolCore
import SwiftParser
import SwiftSyntax
import Testing

private func scan(_ source: String) -> ComponentScanner {
    let syntax = Parser.parse(source: source)
    let scanner = ComponentScanner(viewMode: .sourceAccurate)
    scanner.walk(syntax)
    return scanner
}

enum ComponentScannerTests {
    // MARK: Multi-Binding Declarations

    struct MultiBinding {
        @Test
        func allBindingsCaptured() {
            let scanner = scan(
                """
                @PinComponent
                public class AppComponent {
                    public var logger: Logger, analytics: Analytics
                }
                """
            )
            #expect(scanner.errors.isEmpty)
            #expect(scanner.components.count == 1)
            let component = scanner.components[0]
            let names = component.properties.map(\.name)
            #expect(names.contains("logger"))
            #expect(names.contains("analytics"))
        }

        @Test
        func singleBindingStillWorks() {
            let scanner = scan(
                """
                @PinComponent
                public class AppComponent {
                    public var logger: Logger
                }
                """
            )
            #expect(scanner.errors.isEmpty)
            #expect(scanner.components[0].properties.count == 1)
            #expect(scanner.components[0].properties[0].name == "logger")
        }
    }

    // MARK: Nested Component Detection

    struct NestedComponents {
        @Test
        func nestedPinComponentEmitsError() {
            let scanner = scan(
                """
                @PinComponent
                public class AppComponent {
                    public lazy var config: AppConfig

                    @PinComponent
                    public class NestedFeature {
                        public lazy var value: Int
                    }
                }
                """
            )
            #expect(scanner.errors.count == 1)
            #expect(scanner.errors[0].contains("NestedFeature"))
            #expect(scanner.errors[0].contains("nested"))
        }

        @Test
        func nestedInsideNonPinClassEmitsError() {
            let scanner = scan(
                """
                class Container {
                    @PinComponent
                    public class NestedFeature {
                        public lazy var value: Int
                    }
                }
                """
            )
            #expect(scanner.errors.count == 1)
            #expect(scanner.errors[0].contains("NestedFeature"))
            #expect(scanner.errors[0].contains("nested"))
        }

        @Test
        func nestedInsideStructEmitsError() {
            let scanner = scan(
                """
                struct Container {
                    @PinComponent
                    public class NestedFeature {
                        public lazy var value: Int
                    }
                }
                """
            )
            #expect(scanner.errors.count == 1)
            #expect(scanner.errors[0].contains("NestedFeature"))
            #expect(scanner.errors[0].contains("nested"))
        }

        @Test
        func nestedInsideEnumEmitsError() {
            let scanner = scan(
                """
                enum Container {
                    @PinComponent
                    public class NestedFeature {
                        public lazy var value: Int
                    }
                }
                """
            )
            #expect(scanner.errors.count == 1)
            #expect(scanner.errors[0].contains("NestedFeature"))
            #expect(scanner.errors[0].contains("nested"))
        }

        @Test
        func topLevelComponentsNotAffected() {
            let scanner = scan(
                """
                @PinComponent
                public class AppComponent {
                    public lazy var config: AppConfig
                }

                @PinComponent
                public class FeatureComponent {
                    public lazy var value: Int
                }
                """
            )
            #expect(scanner.errors.isEmpty)
            #expect(scanner.components.count == 2)
        }
    }

    // MARK: Generic Subcomponent Detection

    struct GenericSubcomponents {
        @Test
        func genericSubcomponentTypeEmitsError() {
            let scanner = scan(
                """
                @PinComponent
                public class AppComponent {
                    @PinSubcomponent public var feature: FeatureComponent<String>
                }
                """
            )
            #expect(scanner.errors.count == 1)
            #expect(scanner.errors[0].contains("generic"))
            #expect(scanner.components[0].subcomponents.isEmpty)
        }

        @Test
        func concreteSubcomponentTypeAccepted() {
            let scanner = scan(
                """
                @PinComponent
                public class AppComponent {
                    @PinSubcomponent public var feature: FeatureComponent
                }
                """
            )
            #expect(scanner.errors.isEmpty)
            #expect(scanner.components[0].subcomponents.count == 1)
            #expect(scanner.components[0].subcomponents[0].typeName == "FeatureComponent")
        }

        @Test
        func qualifiedInitializerWithoutAnnotationEmitsError() {
            let scanner = scan(
                """
                @PinComponent
                public class AppComponent {
                    public var nested = Outer.Nested()
                }
                """
            )
            #expect(scanner.errors.count == 1)
            #expect(scanner.errors[0].contains("type annotation"))
        }

        @Test
        func genericRegularPropertyStillAllowed() {
            let scanner = scan(
                """
                @PinComponent
                public class AppComponent {
                    public var cache: Cache<String>
                }
                """
            )
            #expect(scanner.errors.isEmpty)
            #expect(scanner.components[0].properties.count == 1)
            #expect(scanner.components[0].properties[0].type == "Cache<String>")
        }
    }

    // MARK: Internal Property Visibility

    struct InternalProperties {
        @Test
        func publicComponentCollectsInternalProperties() {
            let scanner = scan(
                """
                @PinComponent
                public class AppComponent {
                    public var api: API
                    var config: AppConfig
                }
                """
            )
            #expect(scanner.errors.isEmpty)
            let component = scanner.components[0]
            #expect(component.properties.count == 1)
            #expect(component.properties[0].name == "api")
            #expect(component.internalProperties.count == 1)
            #expect(component.internalProperties[0].name == "config")
        }

        @Test
        func internalComponentHasNoInternalProperties() {
            let scanner = scan(
                """
                @PinComponent
                class AppComponent {
                    var config: AppConfig
                    var logger: Logger
                }
                """
            )
            #expect(scanner.errors.isEmpty)
            let component = scanner.components[0]
            #expect(component.properties.count == 2)
            #expect(component.internalProperties.isEmpty)
        }

        @Test
        func privatePropertiesExcludedFromBothTiers() {
            let scanner = scan(
                """
                @PinComponent
                public class AppComponent {
                    public var api: API
                    var config: AppConfig
                    private var secret: String
                    fileprivate var local: Int
                }
                """
            )
            #expect(scanner.errors.isEmpty)
            let component = scanner.components[0]
            #expect(component.properties.count == 1)
            #expect(component.properties[0].name == "api")
            #expect(component.internalProperties.count == 1)
            #expect(component.internalProperties[0].name == "config")
        }

        @Test
        func packageComponentCollectsInternalProperties() {
            let scanner = scan(
                """
                @PinComponent
                package class AppComponent {
                    package var api: API
                    var config: AppConfig
                }
                """
            )
            #expect(scanner.errors.isEmpty)
            let component = scanner.components[0]
            #expect(component.properties.count == 1)
            #expect(component.properties[0].name == "api")
            #expect(component.internalProperties.count == 1)
            #expect(component.internalProperties[0].name == "config")
        }
    }

    // MARK: Provider Parsing

    struct Provider {
        @Test
        func shorthandWithProvider() {
            let scanner = scan(
                """
                @PinComponent(Logger.self, provider: AppComponent.self)
                public class CarPlayComponent {
                }
                """
            )
            #expect(scanner.errors.isEmpty)
            #expect(scanner.components.count == 1)
            let component = scanner.components[0]
            #expect(component.dependencies.count == 1)
            #expect(component.dependencies[0].name == "logger")
            #expect(component.provider == "AppComponent")
        }

        @Test
        func verboseWithProvider() {
            let scanner = scan(
                """
                @PinComponent(dependencies: [PinDependency(Logger.self)], provider: AppComponent.self)
                public class CarPlayComponent {
                }
                """
            )
            #expect(scanner.errors.isEmpty)
            let component = scanner.components[0]
            #expect(component.dependencies.count == 1)
            #expect(component.provider == "AppComponent")
        }

        @Test
        func noProviderReturnsNil() {
            let scanner = scan(
                """
                @PinComponent(Logger.self)
                public class FeatureComponent {
                }
                """
            )
            #expect(scanner.errors.isEmpty)
            #expect(scanner.components[0].provider == nil)
        }

        @Test
        func rootComponentHasNoProvider() {
            let scanner = scan(
                """
                @PinComponent
                public class AppComponent {
                    public var logger: Logger
                }
                """
            )
            #expect(scanner.errors.isEmpty)
            #expect(scanner.components[0].provider == nil)
        }
    }
}
