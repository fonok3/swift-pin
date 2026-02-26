public final class AppConfig: Sendable {
    // MARK: Properties

    public let appName: String

    // MARK: Lifecycle

    public init(appName: String) {
        self.appName = appName
    }
}
