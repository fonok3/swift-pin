import Pin

@PinComponent(Logger.self)
@MainActor
final class FeatureComponent {
    lazy var dashboard: Dashboard = .init(logger: dependency.logger)

    @PinSubcomponent
    var detail: DetailComponent
}
