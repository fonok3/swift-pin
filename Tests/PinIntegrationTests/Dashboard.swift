final class Dashboard: Sendable {
    // MARK: Properties

    private let logger: Logger

    // MARK: Lifecycle

    init(logger: Logger) {
        self.logger = logger
    }

    // MARK: Functions

    func show() -> String {
        logger.log("Dashboard shown")
    }
}
