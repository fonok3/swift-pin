import SwiftDiagnostics

enum MainActorFixIt: FixItMessage {
    case addMainActor

    // MARK: Computed Properties

    var fixItID: MessageID {
        MessageID(domain: "PinMacros", id: "\(self)")
    }

    var message: String {
        switch self {
        case .addMainActor:
            "Add '@MainActor'"
        }
    }
}
