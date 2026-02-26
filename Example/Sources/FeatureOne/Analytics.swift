public final class Analytics: Sendable {
    // MARK: Lifecycle

    public init() {}

    // MARK: Functions

    public func track(_ event: String) {
        print("[ANALYTICS] \(event)")
    }
}
