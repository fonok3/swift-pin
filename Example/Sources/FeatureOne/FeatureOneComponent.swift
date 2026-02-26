import Pin

@PinComponent
@MainActor public final class FeatureOneComponent {
    public lazy var logger: Logger = .init()
    public lazy var analytics: Analytics = .init()
}
