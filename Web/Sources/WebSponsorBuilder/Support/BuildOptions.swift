import Foundation

struct BuildOptions: Sendable {
  let outputDirectory: URL
  let publicDirectory: URL
  let apiBaseURL: String

  init(arguments: [String], environment: [String: String] = ProcessInfo.processInfo.environment)
    throws
  {
    var outputDirectory = URL(
      fileURLWithPath: AppConfiguration.outputDirectory(environment: environment), isDirectory: true
    )
    var publicDirectory = URL(fileURLWithPath: "Public", isDirectory: true)
    var apiBaseURL = AppConfiguration.apiBaseURL(environment: environment)

    var index = 0
    while index < arguments.count {
      let argument = arguments[index]
      switch argument {
      case "--output":
        index += 1
        guard index < arguments.count else { throw BuildError.missingValue("--output") }
        outputDirectory = URL(fileURLWithPath: arguments[index], isDirectory: true)
      case "--public-dir":
        index += 1
        guard index < arguments.count else { throw BuildError.missingValue("--public-dir") }
        publicDirectory = URL(fileURLWithPath: arguments[index], isDirectory: true)
      case "--api-base-url":
        index += 1
        guard index < arguments.count else { throw BuildError.missingValue("--api-base-url") }
        apiBaseURL = arguments[index]
      default:
        throw BuildError.unknownArgument(argument)
      }
      index += 1
    }

    self.outputDirectory = outputDirectory.standardizedFileURL
    self.publicDirectory = publicDirectory.standardizedFileURL
    self.apiBaseURL = apiBaseURL
  }
}

enum BuildError: LocalizedError {
  case missingValue(String)
  case unknownArgument(String)
  case missingPublicDirectory(String)

  var errorDescription: String? {
    switch self {
    case .missingValue(let argument):
      return "Missing value for \(argument)."
    case .unknownArgument(let argument):
      return "Unknown argument: \(argument)."
    case .missingPublicDirectory(let path):
      return
        "Public asset directory does not exist: \(path). Pass --public-dir <path> to point at an existing directory."
    }
  }
}
