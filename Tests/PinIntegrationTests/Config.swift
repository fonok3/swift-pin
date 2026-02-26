/// An internal type that cannot be made public — used to test
/// internal property forwarding through InternalProviding.
final class Config: Sendable {
    // MARK: Properties

    let appName: String

    // MARK: Lifecycle

    init(appName: String = "TestApp") {
        self.appName = appName
    }
}
