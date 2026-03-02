public struct SubcomponentInfo: Equatable, Sendable {
    public let propertyName: String
    public let typeName: String

    public init(propertyName: String, typeName: String) {
        self.propertyName = propertyName
        self.typeName = typeName
    }
}
