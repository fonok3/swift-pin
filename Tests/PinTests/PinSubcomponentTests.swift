import Testing

enum PinSubcomponentTests {
    struct ValidUsage {
        @Test
        func generatesAccessor() {
            assertMacroExpansion(
                """
                @PinSubcomponent
                var child: ChildComponent
                """,
                expandedSource: """
                    var child: ChildComponent {
                        get {
                            _child
                        }
                    }
                    """,
                macros: testMacros
            )
        }

        @Test
        func withPublicModifier() {
            assertMacroExpansion(
                """
                @PinSubcomponent
                public var child: ChildComponent
                """,
                expandedSource: """
                    public var child: ChildComponent {
                        get {
                            _child
                        }
                    }
                    """,
                macros: testMacros
            )
        }
    }

    struct InvalidUsage {
        @Test
        func onLetEmitsError() {
            assertMacroExpansion(
                """
                @PinSubcomponent
                let child: ChildComponent
                """,
                expandedSource: """
                    let child: ChildComponent
                    """,
                diagnostics: [
                    DiagnosticSpec(
                        message: "@PinSubcomponent requires 'var', not 'let'",
                        line: 2,
                        column: 1
                    )
                ],
                macros: testMacros
            )
        }

        @Test
        func onLazyVarEmitsError() {
            assertMacroExpansion(
                """
                @PinSubcomponent
                lazy var child: ChildComponent
                """,
                expandedSource: """
                    lazy var child: ChildComponent
                    """,
                diagnostics: [
                    DiagnosticSpec(
                        message:
                            "@PinSubcomponent generates lazy initialization automatically; remove the 'lazy' modifier",
                        line: 2,
                        column: 6
                    )
                ],
                macros: testMacros
            )
        }

        @Test
        func withInitializerEmitsError() {
            assertMacroExpansion(
                """
                @PinSubcomponent
                var child: ChildComponent = ChildComponent(dependency: self)
                """,
                expandedSource: """
                    var child: ChildComponent = ChildComponent(dependency: self)
                    """,
                diagnostics: [
                    DiagnosticSpec(
                        message:
                            "@PinSubcomponent must not have an initializer; Pin generates initialization automatically",
                        line: 2,
                        column: 5
                    )
                ],
                macros: testMacros
            )
        }

        @Test
        func withoutTypeAnnotationEmitsError() {
            assertMacroExpansion(
                """
                @PinSubcomponent
                var child = ChildComponent()
                """,
                expandedSource: """
                    var child = ChildComponent()
                    """,
                diagnostics: [
                    DiagnosticSpec(
                        message: "@PinSubcomponent property must have a type annotation",
                        line: 2,
                        column: 5
                    )
                ],
                macros: testMacros
            )
        }
    }
}
