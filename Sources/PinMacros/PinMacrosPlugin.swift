import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct PinMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        PinComponentMacro.self,
        PinSubcomponentMacro.self
    ]
}
