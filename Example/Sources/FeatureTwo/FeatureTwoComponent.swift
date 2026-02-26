import FeatureOne
import Pin

@PinComponent(Logger.self)
@MainActor public final class FeatureTwoComponent {
    public lazy var dashboard: Dashboard = .init(logger: dependency.logger)
}
