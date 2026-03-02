final class Dashboard: Sendable {
    private let logger: Logger

    init(logger: Logger) {
        self.logger = logger
    }

    func show() -> String {
        logger.log("Dashboard shown")
    }
}
