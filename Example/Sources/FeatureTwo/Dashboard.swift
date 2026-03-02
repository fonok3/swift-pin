import FeatureOne

public final class Dashboard: Sendable {
    private let logger: Logger

    public init(logger: Logger) {
        self.logger = logger
    }

    public func show() {
        logger.log("Dashboard shown")
    }
}
