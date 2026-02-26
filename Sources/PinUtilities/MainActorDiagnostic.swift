import SwiftDiagnostics

enum MainActorDiagnostic: DiagnosticMessage {
    case missingMainActor

    // MARK: Computed Properties

    var severity: DiagnosticSeverity {
        .error
    }

    var message: String {
        switch self {
        case .missingMainActor:
            "Pin components should be annotated with @MainActor for thread-safe lazy initialization"
        }
    }

    var diagnosticID: MessageID {
        MessageID(domain: "PinMacros", id: "\(self)")
    }
}
