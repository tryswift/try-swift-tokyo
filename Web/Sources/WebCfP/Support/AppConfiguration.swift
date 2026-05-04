import Foundation

enum AppConfiguration {
  static let defaultAPIBaseURL = "https://api.tryswift.jp"
  static let defaultOutputDirectory = "Build"

  static func apiBaseURL(environment: [String: String] = ProcessInfo.processInfo.environment)
    -> String
  {
    environment["CFP_API_BASE_URL"] ?? defaultAPIBaseURL
  }

  static func outputDirectory(environment: [String: String] = ProcessInfo.processInfo.environment)
    -> String
  {
    environment["CFPWEB_OUTPUT_DIR"] ?? defaultOutputDirectory
  }
}
