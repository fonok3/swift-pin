public final class Logger: Sendable {
    // MARK: Lifecycle

    public init() {}

    // MARK: Functions

    public func log(_ message: String) {
        print("[LOG] \(message)")
    }
}
