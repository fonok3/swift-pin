/// Used with the verbose `dependencies:` form for named overrides.
///
/// For simple cases, prefer the shorthand: `@PinComponent(Logger.self)`.
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
