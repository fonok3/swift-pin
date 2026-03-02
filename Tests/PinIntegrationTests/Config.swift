/// An internal type that cannot be made public — used to test
/// internal property forwarding through InternalProviding.
final class Config: Sendable {
    let appName: String

    init(appName: String = "TestApp") {
        self.appName = appName
    }
}
