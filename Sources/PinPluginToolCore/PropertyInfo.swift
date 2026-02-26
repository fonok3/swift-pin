public struct PropertyInfo: Equatable, Sendable {
    // MARK: Properties

    public let name: String
    public let type: String

    // MARK: Lifecycle

    public init(name: String, type: String) {
        self.name = name
        self.type = type
    }
}
