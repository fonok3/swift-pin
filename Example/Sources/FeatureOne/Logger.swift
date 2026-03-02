public final class Logger: Sendable {
    public init() {}

    public func log(_ message: String) {
        print("[LOG] \(message)")
    }
}
