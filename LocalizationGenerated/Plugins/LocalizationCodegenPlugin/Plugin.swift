import Foundation
import PackagePlugin

@main
struct LocalizationCodegenPlugin: BuildToolPlugin {

  func createBuildCommands(context: PluginContext, target: Target) async throws -> [Command] {
    // This plugin looks for .xcstrings files in the package and generates Swift code

    // Only run for LocalizationGenerated target
    guard target.name == "LocalizationGenerated" else {
      return []
    }

    let packageDirectory = context.package.directory
    var commands: [Command] = []

    // Known .xcstrings file paths in the iOS and Website packages (sibling directories)
    let xcstringsConfigs: [(path: String, featureName: String)] = [
      ("../iOS/Sources/ScheduleFeature/Localizable.xcstrings", "Schedule"),
      ("../iOS/Sources/trySwiftFeature/Localizable.xcstrings", "TrySwift"),
      ("../Website/Sources/Resources/Localizable.xcstrings", "Website"),
    ]

    for config in xcstringsConfigs {
      let xcstringsPath = packageDirectory.appending(config.path)

      // Check if file exists
      guard FileManager.default.fileExists(atPath: xcstringsPath.string) else {
        print("⚠️ Warning: \(config.path) not found, skipping")
        continue
      }

      // Output file in plugin work directory
      let outputFileName = "\(config.featureName)Strings.swift"
      let outputPath = context.pluginWorkDirectory.appending(outputFileName)

      // Generate code inline (not using external tool)
      do {
        // Parse .xcstrings file
        let inputURL = URL(fileURLWithPath: xcstringsPath.string)
        let entries = try XCStringsParser.parse(fileURL: inputURL)

        // Generate Swift code
        let swiftCode = SwiftCodeGenerator.generate(
          featureName: config.featureName, entries: entries)

        // Write to output file
        let outputURL = URL(fileURLWithPath: outputPath.string)
        try swiftCode.write(to: outputURL, atomically: true, encoding: .utf8)

        print("✅ Generated \(outputFileName) with \(entries.count) strings")
      } catch {
        print("❌ Error generating \(outputFileName): \(error)")
        throw error
      }

      // Add output file as a build command
      commands.append(
        .buildCommand(
          displayName: "Generated \(config.featureName) localization",
          executable: Path("/usr/bin/true"),  // No-op, code already generated above
          arguments: [],
          inputFiles: [xcstringsPath],
          outputFiles: [outputPath]
        ))
    }

    return commands
  }
}
