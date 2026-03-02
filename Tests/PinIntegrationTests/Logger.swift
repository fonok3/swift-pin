final class Logger: Sendable {
    init() {}

    func log(_ message: String) -> String {
        "[LOG] \(message)"
    }
}
