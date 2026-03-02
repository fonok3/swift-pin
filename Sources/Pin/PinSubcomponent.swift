/// Declares a child component owned by its parent.
///
/// Pin creates and owns the child component lazily, injecting `self` as
/// the dependency. The property must be a plain `var` with a type annotation
/// — no `lazy`, no initializer. The enclosing class must be a
/// `@PinComponent`-annotated `@MainActor` class.
///
/// ```swift
/// @PinSubcomponent var feature: FeatureComponent
/// ```
@attached(accessor)
public macro PinSubcomponent() = #externalMacro(module: "PinMacros", type: "PinSubcomponentMacro")
