/// Compile-time marker for named dependency declarations.
///
/// The `@PinComponent` macro reads these declarations from source text at
/// compile time. The values are not retained at runtime.
///
/// For simple cases, prefer the shorthand: `@PinComponent(Logger.self)`.
/// Use `PinDependency` only when you need `named:` overrides.
///
/// ```swift
/// // Shorthand (preferred)
/// @PinComponent(Logger.self, HTTPClient.self)
///
/// // Named override (requires verbose form)
/// @PinComponent(dependencies: [PinDependency(Logger.self, named: "networkLogger")])
/// ```
public struct PinDependency: Sendable {
    public init(_: Any.Type) {}
    public init(_: Any.Type, named _: String) {}
}
