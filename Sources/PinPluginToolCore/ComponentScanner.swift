import PinUtilities
import SwiftSyntax

public final class ComponentScanner: SyntaxVisitor {
    // MARK: Properties

    public var components: [ComponentInfo] = []
    public var imports: [String] = []
    public var errors: [String] = []

    private var typeNestingDepth = 0

    // MARK: Overridden Functions

    override public func visit(_ node: ImportDeclSyntax) -> SyntaxVisitorContinueKind {
        imports.append(node.trimmedDescription)
        return .skipChildren
    }

    override public func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        typeNestingDepth += 1

        guard let pinAttr = pinComponentAttribute(node) else {
            return .visitChildren
        }

        let className = node.name.trimmed.text

        if typeNestingDepth > 1 {
            errors.append(
                "\(className): nested @PinComponent classes are not supported"
                    + ", declare the component at the top level"
            )
            return .skipChildren
        }

        let accessLevel = extractAccessLevel(from: node.modifiers)

        var properties: [PropertyInfo] = []
        var internalProperties: [PropertyInfo] = []
        var subcomponents: [SubcomponentInfo] = []

        for member in node.memberBlock.members {
            guard let varDecl = member.decl.as(VariableDeclSyntax.self),
                isInstance(varDecl)
            else {
                continue
            }

            for binding in varDecl.bindings {
                processBinding(
                    binding,
                    varDecl: varDecl,
                    className: className,
                    componentAccess: accessLevel,
                    properties: &properties,
                    internalProperties: &internalProperties,
                    subcomponents: &subcomponents
                )
            }
        }

        let dependencies = parseDependencies(from: pinAttr)
        let provider = parseProvider(from: pinAttr)

        components.append(
            ComponentInfo(
                className: className,
                accessLevel: accessLevel,
                properties: properties,
                internalProperties: internalProperties,
                subcomponents: subcomponents,
                dependencies: dependencies,
                provider: provider
            )
        )

        return .visitChildren
    }

    override public func visitPost(_: ClassDeclSyntax) {
        typeNestingDepth -= 1
    }

    override public func visit(_: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        typeNestingDepth += 1
        return .visitChildren
    }

    override public func visitPost(_: StructDeclSyntax) {
        typeNestingDepth -= 1
    }

    override public func visit(_: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
        typeNestingDepth += 1
        return .visitChildren
    }

    override public func visitPost(_: EnumDeclSyntax) {
        typeNestingDepth -= 1
    }

    // MARK: Functions

    private func processBinding(
        _ binding: PatternBindingSyntax,
        varDecl: VariableDeclSyntax,
        className: String,
        componentAccess: AccessLevel,
        properties: inout [PropertyInfo],
        internalProperties: inout [PropertyInfo],
        subcomponents: inout [SubcomponentInfo]
    ) {
        if hasAttribute("PinSubcomponent", on: varDecl) {
            if let typeName = extractTypeName(from: binding) {
                if typeName.contains("<") {
                    let propName = extractPropertyName(from: binding) ?? "?"
                    errors.append(
                        "\(className).\(propName):"
                            + " generic subcomponent types are not supported"
                            + ", use a concrete type"
                    )
                } else if let propName = extractPropertyName(from: binding) {
                    subcomponents.append(SubcomponentInfo(propertyName: propName, typeName: typeName))
                }
            }
            return
        }

        let propertyAccess = extractAccessLevel(from: varDecl.modifiers)

        // Skip private/fileprivate — never exposed
        guard propertyAccess != .private, propertyAccess != .fileprivate else {
            return
        }

        guard isStored(binding) else {
            return
        }

        guard let propName = extractPropertyName(from: binding) else {
            return
        }

        guard let typeName = extractTypeName(from: binding) else {
            let line = varDecl.startLocation(converter: .init(fileName: "", tree: varDecl.root)).line
            let message =
                "\(className).\(propName) (line \(line)):"
                + " stored property needs a type annotation"
                + " or mark it private to exclude it"
            errors.append(message)
            return
        }

        let info = PropertyInfo(name: propName, type: typeName)

        // Determine if the property belongs in the public or internal tier.
        if isVisibleAtComponentLevel(propertyAccess: propertyAccess, componentAccess: componentAccess) {
            properties.append(info)
        } else {
            internalProperties.append(info)
        }
    }

    /// Whether a property's access level matches the component's external visibility.
    private func isVisibleAtComponentLevel(propertyAccess: AccessLevel, componentAccess: AccessLevel) -> Bool {
        switch componentAccess {
        case .public:
            propertyAccess == .public
        case .package:
            propertyAccess == .public || propertyAccess == .package
        default:
            // Internal components: everything non-private is at component level
            true
        }
    }

    private func pinComponentAttribute(_ node: ClassDeclSyntax) -> AttributeSyntax? {
        for attribute in node.attributes {
            if case .attribute(let attr) = attribute {
                let name = attr.attributeName.trimmedDescription
                if name == "PinComponent" {
                    return attr
                }
            }
        }
        return nil
    }

    /// Parses dependency type arguments from `@PinComponent(Logger.self)` or
    /// `@PinComponent(dependencies: [PinDependency(Logger.self, named: "x")])`.
    private func parseDependencies(from attr: AttributeSyntax) -> [PropertyInfo] {
        guard let arguments = attr.arguments?.as(LabeledExprListSyntax.self) else {
            return []
        }

        // Verbose form: @PinComponent(dependencies: [PinDependency(Logger.self)])
        if let dependenciesArg = arguments.first(where: { $0.label?.text == "dependencies" }),
            let arrayExpr = dependenciesArg.expression.as(ArrayExprSyntax.self)
        {
            var deps: [PropertyInfo] = []
            for element in arrayExpr.elements {
                guard let funcCall = element.expression.as(FunctionCallExprSyntax.self),
                    let firstArg = funcCall.arguments.first,
                    let memberAccess = firstArg.expression.as(MemberAccessExprSyntax.self),
                    memberAccess.declName.baseName.text == "self",
                    let base = memberAccess.base?.as(DeclReferenceExprSyntax.self)
                else {
                    continue
                }
                let typeName = base.baseName.trimmed.text
                let namedArg = funcCall.arguments.first { $0.label?.text == "named" }
                let customName =
                    namedArg
                    .flatMap { $0.expression.as(StringLiteralExprSyntax.self) }
                    .flatMap { $0.segments.first?.as(StringSegmentSyntax.self)?.content.text }
                let resolvedName = customName ?? lowercasePrefix(typeName)
                deps.append(PropertyInfo(name: resolvedName, type: typeName))
            }
            return deps
        }

        // Shorthand form: @PinComponent(Logger.self, HTTPClient.self)
        var deps: [PropertyInfo] = []
        for arg in arguments {
            guard arg.label == nil,
                let memberAccess = arg.expression.as(MemberAccessExprSyntax.self),
                memberAccess.declName.baseName.text == "self",
                let base = memberAccess.base?.as(DeclReferenceExprSyntax.self)
            else {
                continue
            }
            let typeName = base.baseName.trimmed.text
            deps.append(PropertyInfo(name: lowercasePrefix(typeName), type: typeName))
        }
        return deps
    }

    /// Parses the provider argument from `@PinComponent(..., provider: AppComponent.self)`.
    private func parseProvider(from attr: AttributeSyntax) -> String? {
        guard let arguments = attr.arguments?.as(LabeledExprListSyntax.self),
            let providerArg = arguments.first(where: { $0.label?.text == "provider" }),
            let memberAccess = providerArg.expression.as(MemberAccessExprSyntax.self),
            memberAccess.declName.baseName.text == "self",
            let base = memberAccess.base?.as(DeclReferenceExprSyntax.self)
        else {
            return nil
        }
        return base.baseName.trimmed.text
    }

    private func hasAttribute(_ name: String, on varDecl: VariableDeclSyntax) -> Bool {
        varDecl.attributes.contains { attribute in
            if case .attribute(let attr) = attribute {
                return attr.attributeName.trimmedDescription == name
            }
            return false
        }
    }

    private func isInstance(_ varDecl: VariableDeclSyntax) -> Bool {
        !varDecl.modifiers.contains {
            $0.name.tokenKind == .keyword(.static) || $0.name.tokenKind == .keyword(.class)
        }
    }

    /// Treats willSet/didSet-only accessors as stored.
    private func isStored(_ binding: PatternBindingSyntax) -> Bool {
        if let accessorBlock = binding.accessorBlock {
            if case .accessors(let accessors) = accessorBlock.accessors {
                let hasGetOrSet = accessors.contains {
                    $0.accessorSpecifier.tokenKind == .keyword(.get) || $0.accessorSpecifier.tokenKind == .keyword(.set)
                }
                return !hasGetOrSet
            }
            return false
        }
        return true
    }

    private func extractPropertyName(from binding: PatternBindingSyntax) -> String? {
        binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.trimmed.text
    }

    private func extractTypeName(from binding: PatternBindingSyntax) -> String? {
        if let typeAnnotation = binding.typeAnnotation {
            return typeAnnotation.type.trimmed.description
        }

        if let initializer = binding.initializer,
            let funcCall = initializer.value.as(FunctionCallExprSyntax.self)
        {
            // Simple: Foo(...)
            if let declRef = funcCall.calledExpression.as(DeclReferenceExprSyntax.self) {
                return declRef.baseName.trimmed.text
            }
            // Generic: Foo<Bar>(...)
            if let generic = funcCall.calledExpression.as(GenericSpecializationExprSyntax.self),
                let declRef = generic.expression.as(DeclReferenceExprSyntax.self)
            {
                return declRef.baseName.trimmed.text
                    + generic.genericArgumentClause.trimmed.description
            }
            // Qualified expressions like Module.Foo(...) or Outer.Nested(...)
            // are ambiguous, fall through to nil so the caller emits a
            // "needs a type annotation" error.
        }

        return nil
    }
}
