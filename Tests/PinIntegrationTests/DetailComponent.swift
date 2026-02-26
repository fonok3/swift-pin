import Pin

/// A grandchild component that needs `Logger` from its grandparent (`AppComponent`).
///
/// This verifies that dependency forwarding works across multiple levels — `FeatureComponent` forwards `logger`
/// automatically because `@PinComponent` generates a public computed property for each declared dependency.
@PinComponent(Logger.self)
@MainActor
final class DetailComponent {
    lazy var detail: String = dependency.logger.log("Detail loaded")
}
