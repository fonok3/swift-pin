import Testing

private let uninitializedLetError =
    "Stored 'let' property without a default value will not be initialized by the generated init(dependency:); use 'lazy var' or provide a default value"
private let missingMainActorError =
    "Pin components should be annotated with @MainActor for thread-safe lazy initialization"

enum PinComponentTests {
    struct RootBehavior {
        @Test
        func noDepsGeneratesEmptyProtocolAndInit() {
            assertMacroExpansion(
                """
                @PinComponent
                @MainActor public final class AppComponent {
                    public let config: AppConfig = AppConfig()
                }
                """,
                expandedSource: """
                    @MainActor public final class AppComponent {
                        public let config: AppConfig = AppConfig()

                        public init() {
                        }

                        public init(dependency: any AppComponentDependency) {
                        }
                    }

                    @MainActor public protocol AppComponentDependency {
                    }
                    """,
                macros: testMacros
            )
        }

        @Test
        func noDepsWithSubcomponent() {
            assertMacroExpansion(
                """
                @PinComponent
                @MainActor public final class AppComponent {
                    public let logger: Logger = Logger()
                    @PinSubcomponent public var child: ChildComponent
                }
                """,
                expandedSource: """
                    @MainActor public final class AppComponent {
                        public let logger: Logger = Logger()
                        public var child: ChildComponent {
                            get {
                                _child
                            }
                        }

                        public init() {
                        }

                        public init(dependency: any AppComponentDependency) {
                        }

                        private lazy var _child: ChildComponent = ChildComponent(dependency: self)
                    }

                    @MainActor public protocol AppComponentDependency {
                    }
                    """,
                macros: testMacros
            )
        }

        @Test
        func appliedToStructEmitsError() {
            assertMacroExpansion(
                """
                @PinComponent
                public struct NotAClass {
                    public let value: Int
                }
                """,
                expandedSource: """
                    public struct NotAClass {
                        public let value: Int
                    }
                    """,
                diagnostics: [
                    DiagnosticSpec(
                        message: "@PinComponent can only be applied to a class declaration",
                        line: 1,
                        column: 1
                    )
                ],
                macros: testMacros
            )
        }
    }

    struct MainActorWarning {
        @Test
        func componentWithoutMainActorEmitsWarning() {
            assertMacroExpansion(
                """
                @PinComponent(Logger.self)
                public final class FeatureComponent {
                }
                """,
                expandedSource: """
                    public final class FeatureComponent {

                        private let dependency: any FeatureComponentDependency

                        public init(dependency: any FeatureComponentDependency) {
                            self.dependency = dependency
                        }

                        public var _logger: Logger {
                            dependency._logger
                        }
                    }

                    @MainActor public protocol FeatureComponentDependency {
                        var _logger: Logger {
                            get
                        }
                    }
                    """,
                diagnostics: [
                    DiagnosticSpec(
                        message: missingMainActorError,
                        line: 2,
                        column: 14,
                        severity: .error,
                        fixIts: [FixItSpec(message: "Add '@MainActor'")]
                    )
                ],
                macros: testMacros
            )
        }

        @Test
        func rootWithoutMainActorEmitsWarning() {
            assertMacroExpansion(
                """
                @PinComponent
                public final class AppComponent {
                }
                """,
                expandedSource: """
                    public final class AppComponent {

                        public init() {
                        }

                        public init(dependency: any AppComponentDependency) {
                        }
                    }

                    @MainActor public protocol AppComponentDependency {
                    }
                    """,
                diagnostics: [
                    DiagnosticSpec(
                        message: missingMainActorError,
                        line: 2,
                        column: 14,
                        severity: .error,
                        fixIts: [FixItSpec(message: "Add '@MainActor'")]
                    )
                ],
                macros: testMacros
            )
        }
    }

    struct Dependencies {
        @Test
        func emptyArrayTreatedAsRoot() {
            assertMacroExpansion(
                """
                @PinComponent(dependencies: [])
                @MainActor public final class FeatureComponent {
                    public let value: Int = 0
                }
                """,
                expandedSource: """
                    @MainActor public final class FeatureComponent {
                        public let value: Int = 0

                        public init() {
                        }

                        public init(dependency: any FeatureComponentDependency) {
                        }
                    }

                    @MainActor public protocol FeatureComponentDependency {
                    }
                    """,
                macros: testMacros
            )
        }

        @Test
        func withTypes() {
            let source =
                "@PinComponent(dependencies: [PinDependency(Logger.self), PinDependency(URLSession.self)])\n@MainActor public final class FeatureComponent {\n    public let value: Int\n}"
            assertMacroExpansion(
                source,
                expandedSource: """
                    @MainActor public final class FeatureComponent {
                        public let value: Int

                        private let dependency: any FeatureComponentDependency

                        public init(dependency: any FeatureComponentDependency) {
                            self.dependency = dependency
                        }

                        public var _logger: Logger {
                            dependency._logger
                        }

                        public var _urlSession: URLSession {
                            dependency._urlSession
                        }
                    }

                    @MainActor public protocol FeatureComponentDependency {
                        var _logger: Logger {
                            get
                        }
                        var _urlSession: URLSession {
                            get
                        }
                    }
                    """,
                diagnostics: [
                    DiagnosticSpec(message: uninitializedLetError, line: 3, column: 16, severity: .error)
                ],
                macros: testMacros
            )
        }

        @Test
        func lowercasePrefixNaming() {
            assertMacroExpansion(
                """
                @PinComponent(dependencies: [PinDependency(AFNetworkClient.self)])
                @MainActor public final class MyComponent {
                }
                """,
                expandedSource: """
                    @MainActor public final class MyComponent {

                        private let dependency: any MyComponentDependency

                        public init(dependency: any MyComponentDependency) {
                            self.dependency = dependency
                        }

                        public var _afNetworkClient: AFNetworkClient {
                            dependency._afNetworkClient
                        }
                    }

                    @MainActor public protocol MyComponentDependency {
                        var _afNetworkClient: AFNetworkClient {
                            get
                        }
                    }
                    """,
                macros: testMacros
            )
        }

        @Test
        func withNamedOverride() {
            let source =
                #"@PinComponent(dependencies: [PinDependency(Logger.self, named: "networkLogger"), PinDependency(URLSession.self)])"#
                + "\n@MainActor public final class FeatureComponent {\n}"
            assertMacroExpansion(
                source,
                expandedSource: """
                    @MainActor public final class FeatureComponent {

                        private let dependency: any FeatureComponentDependency

                        public init(dependency: any FeatureComponentDependency) {
                            self.dependency = dependency
                        }

                        public var _networkLogger: Logger {
                            dependency._networkLogger
                        }

                        public var _urlSession: URLSession {
                            dependency._urlSession
                        }
                    }

                    @MainActor public protocol FeatureComponentDependency {
                        var _networkLogger: Logger {
                            get
                        }
                        var _urlSession: URLSession {
                            get
                        }
                    }
                    """,
                macros: testMacros
            )
        }

        @Test
        func shorthandForm() {
            assertMacroExpansion(
                """
                @PinComponent(Logger.self, HTTPClient.self)
                @MainActor public final class FeatureComponent {
                }
                """,
                expandedSource: """
                    @MainActor public final class FeatureComponent {

                        private let dependency: any FeatureComponentDependency

                        public init(dependency: any FeatureComponentDependency) {
                            self.dependency = dependency
                        }

                        public var _logger: Logger {
                            dependency._logger
                        }

                        public var _httpClient: HTTPClient {
                            dependency._httpClient
                        }
                    }

                    @MainActor public protocol FeatureComponentDependency {
                        var _logger: Logger {
                            get
                        }
                        var _httpClient: HTTPClient {
                            get
                        }
                    }
                    """,
                macros: testMacros
            )
        }

        @Test
        func accessLevelPropagated() {
            assertMacroExpansion(
                """
                @PinComponent(Logger.self)
                @MainActor package class PackageComponent {
                }
                """,
                expandedSource: """
                    @MainActor package class PackageComponent {

                        private let dependency: any PackageComponentDependency

                        package init(dependency: any PackageComponentDependency) {
                            self.dependency = dependency
                        }

                        package var _logger: Logger {
                            dependency._logger
                        }
                    }

                    @MainActor package protocol PackageComponentDependency {
                        var _logger: Logger {
                            get
                        }
                    }
                    """,
                macros: testMacros
            )
        }
    }

    struct DependencyValidation {
        @Test
        func invalidNameEmitsError() {
            let source =
                #"@PinComponent(dependencies: [PinDependency(Logger.self, named: "123invalid")])"#
                + "\n@MainActor public final class FeatureComponent {\n}"
            assertMacroExpansion(
                source,
                expandedSource: """
                    @MainActor public final class FeatureComponent {

                        public init() {
                        }

                        public init(dependency: any FeatureComponentDependency) {
                        }
                    }

                    @MainActor public protocol FeatureComponentDependency {
                    }
                    """,
                diagnostics: [
                    DiagnosticSpec(
                        message: "'named:' must be a valid Swift identifier",
                        line: 1,
                        column: 57
                    )
                ],
                macros: testMacros
            )
        }

        @Test
        func duplicateNameEmitsError() {
            let source =
                "@PinComponent(dependencies: [PinDependency(Logger.self), PinDependency(Logger.self)])\n@MainActor public final class FeatureComponent {\n}"
            assertMacroExpansion(
                source,
                expandedSource: """
                    @MainActor public final class FeatureComponent {

                        private let dependency: any FeatureComponentDependency

                        public init(dependency: any FeatureComponentDependency) {
                            self.dependency = dependency
                        }

                        public var _logger: Logger {
                            dependency._logger
                        }
                    }

                    @MainActor public protocol FeatureComponentDependency {
                        var _logger: Logger {
                            get
                        }
                    }
                    """,
                diagnostics: [
                    DiagnosticSpec(
                        message: "Duplicate dependency name; each dependency must resolve to a unique property name",
                        line: 1,
                        column: 58
                    )
                ],
                macros: testMacros
            )
        }

        @Test
        func duplicateNameViaNamedOverrideEmitsError() {
            let source =
                #"@PinComponent(dependencies: [PinDependency(A.self, named: "x"), PinDependency(B.self, named: "x")])"#
                + "\n@MainActor public final class FeatureComponent {\n}"
            assertMacroExpansion(
                source,
                expandedSource: """
                    @MainActor public final class FeatureComponent {

                        private let dependency: any FeatureComponentDependency

                        public init(dependency: any FeatureComponentDependency) {
                            self.dependency = dependency
                        }

                        public var _x: A {
                            dependency._x
                        }
                    }

                    @MainActor public protocol FeatureComponentDependency {
                        var _x: A {
                            get
                        }
                    }
                    """,
                diagnostics: [
                    DiagnosticSpec(
                        message: "Duplicate dependency name; each dependency must resolve to a unique property name",
                        line: 1,
                        column: 65
                    )
                ],
                macros: testMacros
            )
        }

        @Test
        func unparsableEmitsError() {
            assertMacroExpansion(
                """
                @PinComponent(dependencies: [PinDependency(someVariable)])
                @MainActor public final class FeatureComponent {
                }
                """,
                expandedSource: """
                    @MainActor public final class FeatureComponent {

                        public init() {
                        }

                        public init(dependency: any FeatureComponentDependency) {
                        }
                    }

                    @MainActor public protocol FeatureComponentDependency {
                    }
                    """,
                diagnostics: [
                    DiagnosticSpec(
                        message: "Could not parse dependency, expected PinDependency(Type.self)",
                        line: 1,
                        column: 30
                    )
                ],
                macros: testMacros
            )
        }
    }

    struct ProviderPassthrough {
        @Test
        func shorthandWithProvider() {
            let source =
                "@PinComponent(Logger.self, provider: AppComponent.self)\n@MainActor public final class CarPlayComponent {\n}"
            assertMacroExpansion(
                source,
                expandedSource: """
                    @MainActor public final class CarPlayComponent {

                        private let dependency: any CarPlayComponentDependency

                        public init(dependency: any CarPlayComponentDependency) {
                            self.dependency = dependency
                        }

                        public var _logger: Logger {
                            dependency._logger
                        }
                    }

                    @MainActor public protocol CarPlayComponentDependency {
                        var _logger: Logger {
                            get
                        }
                    }
                    """,
                macros: testMacros
            )
        }

        @Test
        func verboseWithProvider() {
            let source =
                "@PinComponent(dependencies: [PinDependency(Logger.self)], provider: AppComponent.self)\n@MainActor public final class CarPlayComponent {\n}"
            assertMacroExpansion(
                source,
                expandedSource: """
                    @MainActor public final class CarPlayComponent {

                        private let dependency: any CarPlayComponentDependency

                        public init(dependency: any CarPlayComponentDependency) {
                            self.dependency = dependency
                        }

                        public var _logger: Logger {
                            dependency._logger
                        }
                    }

                    @MainActor public protocol CarPlayComponentDependency {
                        var _logger: Logger {
                            get
                        }
                    }
                    """,
                macros: testMacros
            )
        }
    }

    struct Subcomponents {
        @Test
        func childComponentWithSubcomponent() {
            assertMacroExpansion(
                """
                @PinComponent(Logger.self)
                @MainActor public final class MainComponent {
                    @PinSubcomponent public var child: ChildComponent
                }
                """,
                expandedSource: """
                    @MainActor public final class MainComponent {
                        public var child: ChildComponent {
                            get {
                                _child
                            }
                        }

                        private let dependency: any MainComponentDependency

                        public init(dependency: any MainComponentDependency) {
                            self.dependency = dependency
                        }

                        public var _logger: Logger {
                            dependency._logger
                        }

                        private lazy var _child: ChildComponent = ChildComponent(dependency: self)
                    }

                    @MainActor public protocol MainComponentDependency {
                        var _logger: Logger {
                            get
                        }
                    }
                    """,
                macros: testMacros
            )
        }
    }
}
