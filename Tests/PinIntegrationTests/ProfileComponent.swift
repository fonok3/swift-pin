import Pin

/// An internal subcomponent that needs `Config` from its parent.
/// `Config` is internal, so it flows through `InternalProviding`.
@PinComponent(Config.self)
@MainActor
final class ProfileComponent {
    lazy var greeting: String = "Hello from \(dependency.config.appName)"
}
