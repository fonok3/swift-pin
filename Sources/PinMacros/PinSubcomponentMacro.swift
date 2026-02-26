import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

public struct PinSubcomponentMacro: AccessorMacro {
    // MARK: Nested Types

    struct ParsedSubcomponent {
        let propertyName: String
        let typeName: String
    }

    // MARK: Static Functions

    public static func expansion(
        of node: AttributeSyntax,
        providingAccessorsOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [AccessorDeclSyntax] {
        guard let parsed = validateAndDiagnose(node, declaration, in: context) else {
            return []
        }
        return [
            "get { _\(raw: parsed.propertyName) }"
        ]
    }

    /// Parses a `@PinSubcomponent` property and returns its name and type.
    ///
    /// Used by component macros to generate backing stores.
    static func parseSubcomponent(
        from varDecl: VariableDeclSyntax
    ) -> ParsedSubcomponent? {
        guard varDecl.bindingSpecifier.tokenKind == .keyword(.var),
            !varDecl.modifiers.contains(where: { $0.name.tokenKind == .keyword(.lazy) }),
            let binding = varDecl.bindings.first,
            let identifier = binding.pattern.as(IdentifierPatternSyntax.self),
            let typeAnnotation = binding.typeAnnotation,
            binding.initializer == nil
        else {
            return nil
        }

        let propertyName = identifier.identifier.trimmed.text
        let typeName = typeAnnotation.type.trimmedDescription
        return ParsedSubcomponent(propertyName: propertyName, typeName: typeName)
    }

    // MARK: Private

    private static func validateAndDiagnose(
        _ node: AttributeSyntax,
        _ declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) -> ParsedSubcomponent? {
        guard let varDecl = declaration.as(VariableDeclSyntax.self) else {
            context.diagnose(
                Diagnostic(node: node, message: PinDiagnostic.subcomponentRequiresProperty)
            )
            return nil
        }

        guard varDecl.bindingSpecifier.tokenKind == .keyword(.var) else {
            context.diagnose(
                Diagnostic(node: varDecl.bindingSpecifier, message: PinDiagnostic.subcomponentRequiresVar)
            )
            return nil
        }

        let hasLazy = varDecl.modifiers.contains { $0.name.tokenKind == .keyword(.lazy) }
        if hasLazy {
            context.diagnose(
                Diagnostic(node: varDecl.bindingSpecifier, message: PinDiagnostic.subcomponentMustNotBeLazy)
            )
            return nil
        }

        guard let binding = varDecl.bindings.first,
            let identifier = binding.pattern.as(IdentifierPatternSyntax.self)
        else {
            return nil
        }

        guard let typeAnnotation = binding.typeAnnotation else {
            context.diagnose(
                Diagnostic(node: binding, message: PinDiagnostic.subcomponentRequiresTypeAnnotation)
            )
            return nil
        }

        if binding.initializer != nil {
            context.diagnose(
                Diagnostic(node: binding, message: PinDiagnostic.subcomponentMustNotHaveInitializer)
            )
            return nil
        }

        let propertyName = identifier.identifier.trimmed.text
        let typeName = typeAnnotation.type.trimmedDescription
        return ParsedSubcomponent(propertyName: propertyName, typeName: typeName)
    }
}
