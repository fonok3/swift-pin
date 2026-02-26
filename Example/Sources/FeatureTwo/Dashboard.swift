import FeatureOne

public final class Dashboard: Sendable {
    // MARK: Properties

    private let logger: Logger

    // MARK: Lifecycle

    public init(logger: Logger) {
        self.logger = logger
    }

    // MARK: Functions

    public func show() {
        logger.log("Dashboard shown")
    }
}
