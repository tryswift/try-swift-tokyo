import Foundation

struct BuildOptions: Sendable {
  let outputDirectory: URL
  let publicDirectory: URL
  let apiBaseURL: String

  init(arguments: [String], environment: [String: String] = ProcessInfo.processInfo.environment) throws {
    var outputDirectory = URL(fileURLWithPath: AppConfiguration.outputDirectory(environment: environment), isDirectory: true)
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

  var errorDescription: String? {
    switch self {
    case .missingValue(let argument):
      return "Missing value for \(argument)."
    case .unknownArgument(let argument):
      return "Unknown argument: \(argument)."
    }
  }
}

struct StaticSiteBuilder {
  let options: BuildOptions
  private let fileManager = FileManager.default

  func build() throws {
    try resetOutputDirectory()
    try copyPublicAssets()
    try writePages()
    try writeHealthCheck()
    try writeRedirects()
    try writeRouteManifest()
  }

  private func resetOutputDirectory() throws {
    if fileManager.fileExists(atPath: options.outputDirectory.path()) {
      try fileManager.removeItem(at: options.outputDirectory)
    }
    try fileManager.createDirectory(at: options.outputDirectory, withIntermediateDirectories: true)
  }

  private func copyPublicAssets() throws {
    let publicContents = try fileManager.contentsOfDirectory(
      at: options.publicDirectory,
      includingPropertiesForKeys: nil,
      options: [.skipsHiddenFiles]
    )

    for entry in publicContents {
      let destination = options.outputDirectory.appending(path: entry.lastPathComponent, directoryHint: .notDirectory)
      try fileManager.copyItem(at: entry, to: destination)
    }
  }

  private func writePages() throws {
    for route in SiteRoutes.concrete {
      let destination = destinationURL(for: route.path)
      let html = AppLayout(routePath: route.path, page: route.page, apiBaseURL: options.apiBaseURL).render()
      try write(html, to: destination)
    }

    let rootIndex = options.outputDirectory.appending(path: "index.html", directoryHint: .notDirectory)
    let fallback = AppLayout(routePath: "/", page: .home, apiBaseURL: options.apiBaseURL).render()
    try write(fallback, to: rootIndex)
    try write(fallback, to: options.outputDirectory.appending(path: "404.html", directoryHint: .notDirectory))
  }

  private func writeHealthCheck() throws {
    let healthHTML = """
    <!DOCTYPE html>
    <html lang="en">
    <head><meta charset="utf-8"><title>CfPWeb Health</title></head>
    <body><pre>{\"status\":\"ok\",\"service\":\"CfPWeb\"}</pre></body>
    </html>
    """
    try write(healthHTML, to: destinationURL(for: "/health"))
  }

  private func writeRedirects() throws {
    let contents = SiteRoutes.rewriteRules
      .map { rule in
        if rule.from.hasPrefix("/cfp") {
          return "\(rule.from) \(rule.to) 301"
        }
        return "\(rule.from) \(rule.to) 200"
      }
      .joined(separator: "\n") + "\n"
    try write(contents, to: options.outputDirectory.appending(path: "_redirects", directoryHint: .notDirectory))
  }

  private func writeRouteManifest() throws {
    let concrete = SiteRoutes.concrete.map(\.path)
    let rewrites = SiteRoutes.rewriteRules.map { ["from": $0.from, "to": $0.to] }
    let manifest: [String: Any] = [
      "apiBaseURL": options.apiBaseURL,
      "staticRoutes": concrete,
      "rewrites": rewrites,
    ]

    let data = try JSONSerialization.data(withJSONObject: manifest, options: [.prettyPrinted, .sortedKeys])
    let destination = options.outputDirectory.appending(path: "route-manifest.json", directoryHint: .notDirectory)
    try fileManager.createDirectory(at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)
    try data.write(to: destination)
  }

  private func destinationURL(for path: String) -> URL {
    if path == "/" {
      return options.outputDirectory.appending(path: "index.html", directoryHint: .notDirectory)
    }

    let normalized = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    return options.outputDirectory
      .appending(path: normalized, directoryHint: .isDirectory)
      .appending(path: "index.html", directoryHint: .notDirectory)
  }

  private func write(_ contents: String, to destination: URL) throws {
    try fileManager.createDirectory(at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)
    try contents.write(to: destination, atomically: true, encoding: .utf8)
  }
}
