/// Declares a component in the dependency graph.
///
/// `@PinComponent` has three modes:
///
/// - **Root** (no arguments): No dependencies, no generated `init(dependency:)`.
///   ```swift
///   @PinComponent
///   @MainActor public final class AppComponent { … }
///   ```
///
/// - **Subcomponent** (type arguments): Dependencies are injected via a
///   generated `init(dependency:)`. Wire to a parent with `@PinSubcomponent`.
///   ```swift
///   @PinComponent(Logger.self)
///   @MainActor public final class FeatureComponent { … }
///   ```
///
/// - **Unowned** (`from:`): Like a subcomponent, but you control the lifetime.
///   The named component is automatically conformed to this component's
///   `Dependency` protocol, enabling manual instantiation.
///   ```swift
///   @PinComponent(Logger.self, from: AppComponent.self)
///   @MainActor public final class CarPlayComponent { … }
///   ```
///
/// For named dependencies, use the verbose `dependencies:` form with
/// ``PinDependency``.
@attached(peer, names: suffixed(Dependency))
@attached(member, names: named(dependency), named(init), arbitrary)
public macro PinComponent(_ dependencies: Any.Type...) =
    #externalMacro(
        module: "PinMacros",
        type: "PinComponentMacro"
    )

/// See ``PinComponent(_:)-swift.macro`` for full documentation.
@attached(peer, names: suffixed(Dependency))
@attached(member, names: named(dependency), named(init), arbitrary)
public macro PinComponent(_ dependencies: Any.Type..., from: Any.Type) =
    #externalMacro(
        module: "PinMacros",
        type: "PinComponentMacro"
    )

/// See ``PinComponent(_:)-swift.macro`` for full documentation.
@attached(peer, names: suffixed(Dependency))
@attached(member, names: named(dependency), named(init), arbitrary)
public macro PinComponent(dependencies: [PinDependency]) =
    #externalMacro(
        module: "PinMacros",
        type: "PinComponentMacro"
    )

/// See ``PinComponent(_:)-swift.macro`` for full documentation.
@attached(peer, names: suffixed(Dependency))
@attached(member, names: named(dependency), named(init), arbitrary)
public macro PinComponent(dependencies: [PinDependency], from: Any.Type) =
    #externalMacro(
        module: "PinMacros",
        type: "PinComponentMacro"
    )
