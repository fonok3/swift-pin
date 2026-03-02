import PinMacros
import SwiftBasicFormat
import SwiftDiagnostics
import SwiftParser
import SwiftParserDiagnostics
import SwiftSyntax
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacros
import Testing

let testMacros: [String: Macro.Type] = [
    "PinComponent": PinComponentMacro.self,
    "PinSubcomponent": PinSubcomponentMacro.self
]

/// Expands macros in `originalSource` and compares the result against `expectedExpandedSource`.
///
/// Reports failures through Swift Testing.
func assertMacroExpansion(
    _ originalSource: String,
    expandedSource expectedExpandedSource: String,
    diagnostics expectedDiagnostics: [DiagnosticSpec] = [],
    macros: [String: Macro.Type],
    testModuleName: String = "TestModule",
    testFileName: String = "test.swift",
    indentationWidth: Trivia = .spaces(4),
    sourceLocation: Testing.SourceLocation = #_sourceLocation
) {
    let origSourceFile = Parser.parse(source: originalSource)

    let context = BasicMacroExpansionContext(
        sourceFiles: [origSourceFile: .init(moduleName: testModuleName, fullFilePath: testFileName)]
    )

    let expandedSourceFile = origSourceFile.expand(
        macros: macros,
        in: context,
        indentationWidth: indentationWidth
    )

    // Verify expanded source has no parse errors.
    let parseErrors = ParseDiagnosticsGenerator.diagnostics(for: expandedSourceFile)
    if !parseErrors.isEmpty {
        Issue.record(
            "Expanded source contains syntax errors:\n\(DiagnosticsFormatter.annotatedSource(tree: expandedSourceFile, diags: parseErrors))",
            sourceLocation: sourceLocation
        )
    }

    // Compare expanded source.
    let actual = expandedSourceFile.description.trimmingCharacters(in: .newlines)
    let expected = expectedExpandedSource.trimmingCharacters(in: .newlines)
    if actual != expected {
        Issue.record(
            """
            Macro expansion did not produce the expected expanded source
            Actual:
            \(actual)
            Expected:
            \(expected)
            """,
            sourceLocation: sourceLocation
        )
    }

    // Compare diagnostics.
    let actualDiags = context.diagnostics
    if actualDiags.count != expectedDiagnostics.count {
        Issue.record(
            """
            Expected \(expectedDiagnostics.count) diagnostics but received \(actualDiags.count):
            \(actualDiags.map(\.debugDescription).joined(separator: "\n"))
            """,
            sourceLocation: sourceLocation
        )
    } else {
        for (actualDiag, expectedDiag) in zip(actualDiags, expectedDiagnostics) {
            assertDiagnostic(actualDiag, in: context, matches: expectedDiag, sourceLocation: sourceLocation)
        }
    }
}

// MARK: - Private

private func assertDiagnostic(
    _ actualDiag: Diagnostic,
    in context: BasicMacroExpansionContext,
    matches expectedDiag: DiagnosticSpec,
    sourceLocation: Testing.SourceLocation
) {
    if let id = expectedDiag.id, actualDiag.diagnosticID != id {
        Issue.record(
            "Diagnostic ID '\(actualDiag.diagnosticID)' does not match expected '\(id)'",
            sourceLocation: sourceLocation
        )
    }
    if actualDiag.message != expectedDiag.message {
        Issue.record(
            "Diagnostic message '\(actualDiag.message)' does not match expected '\(expectedDiag.message)'",
            sourceLocation: sourceLocation
        )
    }
    let location = context.location(for: actualDiag.position, anchoredAt: actualDiag.node, fileName: "")
    if location.line != expectedDiag.line {
        Issue.record(
            "Diagnostic line \(location.line) does not match expected \(expectedDiag.line)",
            sourceLocation: sourceLocation
        )
    }
    if location.column != expectedDiag.column {
        Issue.record(
            "Diagnostic column \(location.column) does not match expected \(expectedDiag.column)",
            sourceLocation: sourceLocation
        )
    }
    if actualDiag.diagMessage.severity != expectedDiag.severity {
        Issue.record(
            "Diagnostic severity '\(actualDiag.diagMessage.severity)' does not match expected '\(expectedDiag.severity)'",
            sourceLocation: sourceLocation
        )
    }
    if actualDiag.fixIts.count != expectedDiag.fixIts.count {
        Issue.record(
            "Expected \(expectedDiag.fixIts.count) Fix-Its but received \(actualDiag.fixIts.count)",
            sourceLocation: sourceLocation
        )
    } else {
        for (actualFixIt, expectedFixIt) in zip(actualDiag.fixIts, expectedDiag.fixIts)
        where actualFixIt.message.message != expectedFixIt.message {
            Issue.record(
                "Fix-It message '\(actualFixIt.message.message)' does not match expected '\(expectedFixIt.message)'",
                sourceLocation: sourceLocation
            )
        }
    }
}
