/// Declares a component in the dependency graph.
///
/// - No arguments: a root component with no dependencies and no generated `init(dependency:)`.
/// - With type arguments: dependencies are injected via a generated `init(dependency:)`.
/// - With `provider:`: the named component is automatically conformed to this component's
///   `Dependency` protocol, enabling manual instantiation without `@PinSubcomponent`.
@attached(peer, names: suffixed(Dependency))
@attached(member, names: named(dependency), named(init), arbitrary)
public macro PinComponent(_ dependencies: Any.Type...) =
    #externalMacro(
        module: "PinMacros",
        type: "PinComponentMacro"
    )

/// Declares a component with shorthand dependencies and an explicit provider.
@attached(peer, names: suffixed(Dependency))
@attached(member, names: named(dependency), named(init), arbitrary)
public macro PinComponent(_ dependencies: Any.Type..., provider: Any.Type) =
    #externalMacro(
        module: "PinMacros",
        type: "PinComponentMacro"
    )

/// Declares a component with named dependencies.
/// Use the verbose form when you need `named:` overrides.
@attached(peer, names: suffixed(Dependency))
@attached(member, names: named(dependency), named(init), arbitrary)
public macro PinComponent(dependencies: [PinDependency]) =
    #externalMacro(
        module: "PinMacros",
        type: "PinComponentMacro"
    )

/// Declares a component with named dependencies and an explicit provider.
@attached(peer, names: suffixed(Dependency))
@attached(member, names: named(dependency), named(init), arbitrary)
public macro PinComponent(dependencies: [PinDependency], provider: Any.Type) =
    #externalMacro(
        module: "PinMacros",
        type: "PinComponentMacro"
    )

/// Declares a child component. Pin automatically generates lazy
/// initialization and injects `self` as the dependency.
/// Must be a plain `var` with a type annotation.
@attached(accessor)
public macro PinSubcomponent() = #externalMacro(module: "PinMacros", type: "PinSubcomponentMacro")
