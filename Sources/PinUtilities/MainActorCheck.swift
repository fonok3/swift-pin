import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

/// Emits an error if the class is missing `@MainActor`.
public func diagnoseMainActorIfMissing(
    on classDecl: ClassDeclSyntax,
    in context: some MacroExpansionContext
) {
    let hasMainActor = classDecl.attributes.contains { attr in
        guard case .attribute(let attribute) = attr else {
            return false
        }
        return attribute.attributeName.trimmedDescription == "MainActor"
    }

    guard !hasMainActor else {
        return
    }

    let diagnostic = Diagnostic(
        node: classDecl.classKeyword,
        message: MainActorDiagnostic.missingMainActor,
        fixIt: FixIt(
            message: MainActorFixIt.addMainActor,
            changes: [
                .replace(
                    oldNode: Syntax(classDecl.classKeyword),
                    newNode: Syntax(
                        TokenSyntax(
                            .keyword(.class),
                            leadingTrivia: .newlines(1) + classDecl.classKeyword.leadingTrivia,
                            trailingTrivia: classDecl.classKeyword.trailingTrivia,
                            presence: .present
                        )
                    )
                )
            ]
        )
    )

    context.diagnose(diagnostic)
}
