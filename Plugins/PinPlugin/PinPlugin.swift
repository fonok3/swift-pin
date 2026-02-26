import PackagePlugin

@main
struct PinPlugin: BuildToolPlugin {
    func createBuildCommands(context: PluginContext, target: Target) async throws -> [Command] {
        guard let sourceTarget = target as? SourceModuleTarget else {
            return []
        }

        let tool = try context.tool(named: "PinPluginTool")
        let outputDir = context.pluginWorkDirectory
        let outputFile = outputDir.appending(subpath: "PinGenerated.swift")

        let sourceFiles = sourceTarget.sourceFiles(withSuffix: ".swift")
        let inputPaths = sourceFiles.map(\.path)

        guard !inputPaths.isEmpty else {
            return []
        }

        return [
            .buildCommand(
                displayName: "PinPlugin: Generate wiring for \(target.name)",
                executable: tool.path,
                arguments: [outputFile.string] + inputPaths.map(\.string),
                inputFiles: inputPaths,
                outputFiles: [outputFile]
            )
        ]
    }
}
