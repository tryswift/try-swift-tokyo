import Foundation

struct StaticSiteBuilder {
  let options: BuildOptions
  private let fileManager = FileManager.default

  func build() throws {
    try resetOutputDirectory()
    try copyPublicAssets()
    try writePages()
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
    for route in SiteRoutes.concrete {
      let destination = destinationURL(for: route.path)
      let html = route.page.render(apiBaseURL: options.apiBaseURL)
      try write(html, to: destination)
    }

    // Cloudflare Pages serves /index.html for the apex; also seed a 404.html
    // copy of the inquiry landing so unknown paths render the LP.
    let fallback = SponsorPage.inquiry(.en).render(apiBaseURL: options.apiBaseURL)
    try write(
      fallback,
      to: options.outputDirectory.appending(path: "404.html", directoryHint: .notDirectory))
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

  private func writeRouteManifest() throws {
    let concrete = SiteRoutes.concrete.map(\.path)
    let rewrites = SiteRoutes.rewriteRules.map { ["from": $0.from, "to": $0.to] }
    let manifest: [String: Any] = [
      "apiBaseURL": options.apiBaseURL,
      "staticRoutes": concrete,
      "rewrites": rewrites,
    ]

    let data = try JSONSerialization.data(
      withJSONObject: manifest, options: [.prettyPrinted, .sortedKeys])
    let destination = options.outputDirectory.appending(
      path: "route-manifest.json", directoryHint: .notDirectory)
    try fileManager.createDirectory(
      at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)
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
    try fileManager.createDirectory(
      at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)
    try contents.write(to: destination, atomically: true, encoding: .utf8)
  }
}
