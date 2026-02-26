final class Analytics: Sendable {
    // MARK: Lifecycle

    init() {}

    // MARK: Functions

    func track(_ event: String) -> String {
        "[ANALYTICS] \(event)"
    }
}
