import Elementary
import Foundation
import SharedModels

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

  var errorDescription: String? {
    switch self {
    case .missingValue(let argument): return "Missing value for \(argument)."
    case .unknownArgument(let argument): return "Unknown argument: \(argument)."
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
    try writeRedirects()
  }

  private func resetOutputDirectory() throws {
    if fileManager.fileExists(atPath: options.outputDirectory.path()) {
      try fileManager.removeItem(at: options.outputDirectory)
    }
    try fileManager.createDirectory(at: options.outputDirectory, withIntermediateDirectories: true)
  }

  private func copyPublicAssets() throws {
    guard fileManager.fileExists(atPath: options.publicDirectory.path()) else { return }
    let publicContents = try fileManager.contentsOfDirectory(
      at: options.publicDirectory,
      includingPropertiesForKeys: nil,
      options: [.skipsHiddenFiles]
    )
    for entry in publicContents {
      let destination = options.outputDirectory.appending(
        path: entry.lastPathComponent, directoryHint: .notDirectory)
      try fileManager.copyItem(at: entry, to: destination)
    }
  }

  private func writePages() throws {
    for route in SiteRoutes.concrete + SiteRoutes.detailRoutes {
      let destination = destinationURL(for: route.path)
      let html = render(page: route.page, locale: route.locale)
      try write(html, to: destination)
    }

    // Cloudflare Pages serves /404.html for unmatched paths.
    let notFound = render(page: .info, locale: .en)
    try write(
      notFound,
      to: options.outputDirectory.appending(path: "404.html", directoryHint: .notDirectory))
  }

  private func render(page: ScholarshipPage, locale: ScholarshipPortalLocale) -> String {
    switch page {
    case .info:
      return InfoPage(locale: locale, apiBaseURL: options.apiBaseURL).render()
    case .login:
      return LoginRequestPage(locale: locale, apiBaseURL: options.apiBaseURL).render()
    case .loginSent:
      return LoginSentPage(locale: locale, apiBaseURL: options.apiBaseURL).render()
    case .apply:
      return ApplyPage(locale: locale, apiBaseURL: options.apiBaseURL).render()
    case .myApplication:
      return MyApplicationPage(locale: locale, apiBaseURL: options.apiBaseURL).render()
    case .organizerList:
      return ApplicationListPage(locale: locale, apiBaseURL: options.apiBaseURL).render()
    case .organizerDetail:
      return ApplicationDetailPage(locale: locale, apiBaseURL: options.apiBaseURL).render()
    case .organizerBudget:
      return BudgetPage(locale: locale, apiBaseURL: options.apiBaseURL).render()
    }
  }

  private func writeRedirects() throws {
    let contents =
      SiteRoutes.rewriteRules
      .map { rule in "\(rule.from) \(rule.to) 200" }
      .joined(separator: "\n") + "\n"
    try write(
      contents,
      to: options.outputDirectory.appending(path: "_redirects", directoryHint: .notDirectory))
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
    try fileManager.createDirectory(
      at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)
    try contents.write(to: destination, atomically: true, encoding: .utf8)
  }
}
