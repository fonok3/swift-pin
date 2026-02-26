import Foundation
import PinPluginToolCore
import SwiftParser

@main
struct PinPluginTool {
    // MARK: Nested Types

    struct ToolError: Error, CustomStringConvertible {
        let description: String
    }

    // MARK: Static Functions

    static func main() throws {
        let args = Array(CommandLine.arguments.dropFirst())

        guard args.count >= 1 else {
            throw ToolError(description: "Usage: PinPluginTool <output-path> [source-files...]")
        }

        let outputPath = args[0]
        let sourcePaths = Array(args.dropFirst())

        var allComponents: [ComponentInfo] = []
        var allImports: [String] = []
        var allErrors: [String] = []

        for path in sourcePaths {
            let url = URL(fileURLWithPath: path)
            let source = try String(contentsOf: url, encoding: .utf8)
            let syntax = Parser.parse(source: source)
            let scanner = ComponentScanner(viewMode: .sourceAccurate)
            scanner.walk(syntax)
            allComponents.append(contentsOf: scanner.components)
            allImports.append(contentsOf: scanner.imports)

            let fileName = url.lastPathComponent
            for error in scanner.errors {
                allErrors.append("\(fileName): \(error)")
            }
        }

        if !allErrors.isEmpty {
            let joined = allErrors.map { "error: \($0)" }.joined(separator: "\n")
            throw ToolError(description: joined)
        }

        let generator = CodeGenerator(components: allComponents, imports: allImports)

        let cycleErrors = generator.detectCycles()
        if !cycleErrors.isEmpty {
            let joined = cycleErrors.map { "error: \($0)" }.joined(separator: "\n")
            throw ToolError(description: joined)
        }

        let output = generator.generate()

        try output.write(to: URL(fileURLWithPath: outputPath), atomically: true, encoding: .utf8)
    }
}
