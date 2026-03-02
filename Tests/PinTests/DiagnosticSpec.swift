import SwiftDiagnostics

struct DiagnosticSpec {
    let id: MessageID?
    let message: String
    let line: Int
    let column: Int
    let severity: DiagnosticSeverity
    let fixIts: [FixItSpec]

    init(
        id: MessageID? = nil,
        message: String,
        line: Int,
        column: Int,
        severity: DiagnosticSeverity = .error,
        fixIts: [FixItSpec] = []
    ) {
        self.id = id
        self.message = message
        self.line = line
        self.column = column
        self.severity = severity
        self.fixIts = fixIts
    }
}
