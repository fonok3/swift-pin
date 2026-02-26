import SwiftSyntax

public enum AccessLevel: Equatable, Sendable {
    case `public`
    case package
    case `internal`
    case `fileprivate`
    case `private`

    // MARK: Computed Properties

    /// Keyword prefix for generated declarations.
    ///
    /// Empty for `internal` (implicit default).
    public var declarationPrefix: String {
        switch self {
        case .public: "public "
        case .package: "package "
        case .internal: ""
        case .fileprivate: "fileprivate "
        case .private: "private "
        }
    }
}

/// Extracts the access level from declaration modifiers.
///
/// Maps `open` to `.public` since protocols cannot be `open`. Returns `.internal` when no modifier is present.
public func extractAccessLevel(from modifiers: DeclModifierListSyntax) -> AccessLevel {
    for modifier in modifiers {
        switch modifier.name.tokenKind {
        case .keyword(.open): return .public
        case .keyword(.public): return .public
        case .keyword(.package): return .package
        case .keyword(.fileprivate): return .fileprivate
        case .keyword(.private): return .private
        default: continue
        }
    }
    return .internal
}
