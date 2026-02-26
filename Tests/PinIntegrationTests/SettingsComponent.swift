import Pin

/// Demonstrates dependency forwarding through subcomponents.
/// `SettingsComponent` needs `Logger` from its parent and owns a
/// `Config` that its child `ProfileComponent` needs.
@PinComponent(Logger.self)
@MainActor
final class SettingsComponent {
    lazy var config: Config = .init()

    @PinSubcomponent
    var profile: ProfileComponent
}
