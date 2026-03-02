final class Analytics: Sendable {
    init() {}

    func track(_ event: String) -> String {
        "[ANALYTICS] \(event)"
    }
}
