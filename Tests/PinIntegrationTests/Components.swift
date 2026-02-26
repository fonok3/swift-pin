import Pin

@PinComponent
@MainActor
final class AppComponent {
    lazy var logger: Logger = .init()
    lazy var analytics: Analytics = .init()

    @PinSubcomponent
    var feature: FeatureComponent
    @PinSubcomponent
    var settings: SettingsComponent
}
