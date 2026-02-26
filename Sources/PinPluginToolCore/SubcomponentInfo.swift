public struct SubcomponentInfo: Equatable, Sendable {
    // MARK: Properties

    public let propertyName: String
    public let typeName: String

    // MARK: Lifecycle

    public init(propertyName: String, typeName: String) {
        self.propertyName = propertyName
        self.typeName = typeName
    }
}
