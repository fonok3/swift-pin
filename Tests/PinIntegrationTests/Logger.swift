final class Logger: Sendable {
    // MARK: Lifecycle

    init() {}

    // MARK: Functions

    func log(_ message: String) -> String {
        "[LOG] \(message)"
    }
}
