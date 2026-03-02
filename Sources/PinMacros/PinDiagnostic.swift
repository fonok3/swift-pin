import SwiftDiagnostics

enum PinDiagnostic: DiagnosticMessage {
    case requiresClass
    case subcomponentRequiresProperty
    case subcomponentRequiresVar
    case subcomponentRequiresTypeAnnotation
    case subcomponentMustNotHaveInitializer
    case subcomponentMustNotBeLazy
    case invalidDependencyName
    case duplicateDependencyName
    case unparsableDependency
    case uninitializedStoredProperty

    var severity: DiagnosticSeverity {
        .error
    }

    var message: String {
        switch self {
        case .requiresClass:
            "@PinComponent can only be applied to a class declaration"
        case .subcomponentRequiresProperty:
            "@PinSubcomponent can only be applied to a property declaration"
        case .subcomponentRequiresVar:
            "@PinSubcomponent requires 'var', not 'let'"
        case .subcomponentRequiresTypeAnnotation:
            "@PinSubcomponent property must have a type annotation"
        case .subcomponentMustNotHaveInitializer:
            "@PinSubcomponent must not have an initializer; "
                + "Pin generates initialization automatically"
        case .subcomponentMustNotBeLazy:
            "@PinSubcomponent generates lazy initialization automatically; "
                + "remove the 'lazy' modifier"
        case .invalidDependencyName:
            "'named:' must be a valid Swift identifier"
        case .duplicateDependencyName:
            "Duplicate dependency name; "
                + "each dependency must resolve to a unique property name"
        case .uninitializedStoredProperty:
            "Stored 'let' property without a default value "
                + "will not be initialized by the generated init(dependency:); "
                + "use 'lazy var' or provide a default value"
        case .unparsableDependency:
            "Could not parse dependency, expected PinDependency(Type.self)"
        }
    }

    var diagnosticID: MessageID {
        MessageID(domain: "PinMacros", id: "\(self)")
    }
}
