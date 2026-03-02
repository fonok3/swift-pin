import PinUtilities
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct PinComponentMacro: PeerMacro, MemberMacro {
    struct ParsedDependency {
        let type: String
        let name: String?
    }

    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let classDecl = declaration.as(ClassDeclSyntax.self) else {
            context.diagnose(
                Diagnostic(node: node, message: PinDiagnostic.requiresClass)
            )
            return []
        }

        diagnoseMainActorIfMissing(on: classDecl, in: context)

        let className = classDecl.name.trimmed.text
        let accessModifier = extractAccessLevel(from: classDecl.modifiers).declarationPrefix
        let depProtocolName = "\(className)Dependency"

        let deps = parseDependencies(from: node, in: context)

        if deps.isEmpty {
            let depProtocol: DeclSyntax =
                "@MainActor \(raw: accessModifier)protocol \(raw: depProtocolName) {}"
            return [depProtocol]
        }

        let requirements =
            deps
            .map { dep -> String in
                let baseName = dep.name ?? lowercasePrefix(dep.type)
                let underscored = escapedIfKeyword("_" + baseName)
                return "    var \(underscored): \(dep.type) { get }"
            }
            .joined(separator: "\n")
        let depProtocol: DeclSyntax =
            "@MainActor \(raw: accessModifier)protocol \(raw: depProtocolName) {\n\(raw: requirements)\n}"
        return [depProtocol]
    }

    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo _: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let classDecl = declaration.as(ClassDeclSyntax.self) else {
            return []
        }

        let deps = parseDependencies(from: node)

        let className = classDecl.name.trimmed.text
        let depProtocolName = "\(className)Dependency"
        let accessModifier = extractAccessLevel(from: classDecl.modifiers).declarationPrefix

        if deps.isEmpty {
            let defaultInit: DeclSyntax =
                "\(raw: accessModifier)init() {}"
            let dependencyInit: DeclSyntax =
                "\(raw: accessModifier)init(dependency: any \(raw: depProtocolName)) {}"
            var members: [DeclSyntax] = [defaultInit, dependencyInit]
            members.append(contentsOf: generateSubcomponentBackingStores(for: classDecl))
            return members
        }

        // Warn about stored `let` properties without initializers since the
        // generated init(dependency:) won't initialize them.
        for member in classDecl.memberBlock.members {
            guard let varDecl = member.decl.as(VariableDeclSyntax.self),
                varDecl.bindingSpecifier.tokenKind == .keyword(.let),
                !varDecl.modifiers.contains(where: {
                    $0.name.tokenKind == .keyword(.static) || $0.name.tokenKind == .keyword(.class)
                })
            else {
                continue
            }
            for binding in varDecl.bindings {
                if binding.initializer == nil, binding.accessorBlock == nil {
                    context.diagnose(
                        Diagnostic(node: binding, message: PinDiagnostic.uninitializedStoredProperty)
                    )
                }
            }
        }

        let property: DeclSyntax =
            "private let dependency: any \(raw: depProtocolName)"

        let initializer: DeclSyntax =
            "\(raw: accessModifier)init(dependency: any \(raw: depProtocolName)) {\n    self.dependency = dependency\n}"

        var members: [DeclSyntax] = [property, initializer]

        // Generate underscored forwarding properties for each dependency so
        // that the plugin's Providing protocol can forward them through the
        // tree. The underscore signals these are framework-internal — users
        // should access dependencies via `dependency.logger` instead.
        for dep in deps {
            let propName = escapedIfKeyword("_" + (dep.name ?? lowercasePrefix(dep.type)))
            members.append(
                "\(raw: accessModifier)var \(raw: propName): \(raw: dep.type) { dependency.\(raw: propName) }"
            )
        }

        members.append(contentsOf: generateSubcomponentBackingStores(for: classDecl))
        return members
    }

    /// Parses dependencies with diagnostic reporting.
    private static func parseDependencies(
        from node: AttributeSyntax,
        in context: some MacroExpansionContext
    ) -> [ParsedDependency] {
        parseDependenciesCore(from: node) { diagNode, message in
            context.diagnose(Diagnostic(node: diagNode, message: message))
        }
    }

    /// Parses dependencies silently, skipping invalid entries without diagnostics.
    ///
    /// Used by the member expansion — the peer expansion handles all reporting.
    private static func parseDependencies(
        from node: AttributeSyntax
    ) -> [ParsedDependency] {
        parseDependenciesCore(from: node, diagnose: nil)
    }

    private static func parseDependenciesCore(
        from node: AttributeSyntax,
        diagnose: ((Syntax, PinDiagnostic) -> Void)?
    ) -> [ParsedDependency] {
        guard let arguments = node.arguments?.as(LabeledExprListSyntax.self) else {
            return []
        }

        // Verbose form: @PinComponent(dependencies: [PinDependency(Logger.self)])
        if let dependenciesArg = arguments.first(where: { $0.label?.text == "dependencies" }),
            let arrayExpr = dependenciesArg.expression.as(ArrayExprSyntax.self)
        {
            return parseVerboseDependencies(arrayExpr, diagnose: diagnose)
        }

        // Shorthand form: @PinComponent(Logger.self, HTTPClient.self)
        return parseShorthandDependencies(arguments, diagnose: diagnose)
    }

    private static func parseVerboseDependencies(
        _ arrayExpr: ArrayExprSyntax,
        diagnose: ((Syntax, PinDiagnostic) -> Void)?
    ) -> [ParsedDependency] {
        var deps: [ParsedDependency] = []
        var seenNames: Set<String> = []
        for element in arrayExpr.elements {
            guard let funcCall = element.expression.as(FunctionCallExprSyntax.self),
                let firstArg = funcCall.arguments.first,
                let memberAccess = firstArg.expression.as(MemberAccessExprSyntax.self),
                memberAccess.declName.baseName.text == "self",
                let base = memberAccess.base?.as(DeclReferenceExprSyntax.self)
            else {
                diagnose?(Syntax(element.expression), .unparsableDependency)
                continue
            }

            let typeName = base.baseName.trimmed.text

            let namedArg = funcCall.arguments.first { $0.label?.text == "named" }
            let customName: String? =
                namedArg
                .flatMap { $0.expression.as(StringLiteralExprSyntax.self) }
                .flatMap { $0.segments.first?.as(StringSegmentSyntax.self)?.content.text }

            if let customName, !isValidSwiftIdentifier(customName) {
                if let namedArg {
                    diagnose?(Syntax(namedArg), .invalidDependencyName)
                }
                continue
            }

            let resolvedName = customName ?? lowercasePrefix(typeName)
            if !seenNames.insert(resolvedName).inserted {
                diagnose?(Syntax(element.expression), .duplicateDependencyName)
                continue
            }

            deps.append(ParsedDependency(type: typeName, name: customName))
        }

        return deps
    }

    private static func parseShorthandDependencies(
        _ arguments: LabeledExprListSyntax,
        diagnose: ((Syntax, PinDiagnostic) -> Void)?
    ) -> [ParsedDependency] {
        var deps: [ParsedDependency] = []
        var seenNames: Set<String> = []
        for arg in arguments {
            // Skip labeled arguments (e.g. `from:`) — they're handled elsewhere
            if arg.label != nil {
                continue
            }

            guard let memberAccess = arg.expression.as(MemberAccessExprSyntax.self),
                memberAccess.declName.baseName.text == "self",
                let base = memberAccess.base?.as(DeclReferenceExprSyntax.self)
            else {
                diagnose?(Syntax(arg.expression), .unparsableDependency)
                continue
            }

            let typeName = base.baseName.trimmed.text
            let resolvedName = lowercasePrefix(typeName)
            if !seenNames.insert(resolvedName).inserted {
                diagnose?(Syntax(arg.expression), .duplicateDependencyName)
                continue
            }

            deps.append(ParsedDependency(type: typeName, name: nil))
        }

        return deps
    }
}
