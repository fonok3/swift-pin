import PinUtilities

public struct ComponentInfo: Equatable, Sendable {
    public let className: String
    public let accessLevel: AccessLevel
    public let properties: [PropertyInfo]
    /// Properties visible only within the target (internal access on a public component).
    public let internalProperties: [PropertyInfo]
    public let subcomponents: [SubcomponentInfo]
    public let dependencies: [PropertyInfo]
    public let dependencySource: String?

    public init(
        className: String,
        accessLevel: AccessLevel,
        properties: [PropertyInfo],
        internalProperties: [PropertyInfo] = [],
        subcomponents: [SubcomponentInfo],
        dependencies: [PropertyInfo] = [],
        dependencySource: String? = nil
    ) {
        self.className = className
        self.accessLevel = accessLevel
        self.properties = properties
        self.internalProperties = internalProperties
        self.subcomponents = subcomponents
        self.dependencies = dependencies
        self.dependencySource = dependencySource
    }
}
