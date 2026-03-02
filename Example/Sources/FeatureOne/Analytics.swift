public final class Analytics: Sendable {
    public init() {}

    public func track(_ event: String) {
        print("[ANALYTICS] \(event)")
    }
}
