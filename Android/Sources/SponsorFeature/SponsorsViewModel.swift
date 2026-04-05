import Foundation
import SharedModels
import SkipModel

private let resourceBaseURLString =
  "https://raw.githubusercontent.com/tryswift/try-swift-tokyo/main/DataClient/Sources/DataClient/Resources"

private func androidAssetBundle() -> Bundle? {
  #if SKIP
    guard let rootURL = URL(string: "asset:/") else { return nil }
    return Bundle(url: rootURL)
  #else
    return nil
  #endif
}

@Observable
@MainActor
public final class SponsorsViewModel {
  public var sponsors: Sponsors?
  public var isLoading = false
  public var errorMessage: String?

  public init() {}

  public func loadSponsors() {
    guard sponsors == nil else { return }
    isLoading = true
    errorMessage = nil

    Task {
      do {
        sponsors = try await loadSponsorsData()
      } catch {
        errorMessage = error.localizedDescription
      }
      isLoading = false
    }
  }

  private func loadSponsorsData() async throws -> Sponsors {
    let data: Data
    if let url = Bundle.module.url(forResource: "2026-sponsors", withExtension: "json") {
      data = try Data(contentsOf: url)
    } else if let assetBundle = androidAssetBundle(),
      let assetURL = assetBundle.url(forResource: "2026-sponsors", withExtension: "json")
    {
      data = try Data(contentsOf: assetURL)
    } else if let remoteURL = URL(string: "\(resourceBaseURLString)/2026-sponsors.json") {
      let (remoteData, _) = try await URLSession.shared.data(from: remoteURL)
      data = remoteData
    } else {
      throw SponsorError.fileNotFound
    }

    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    return try decoder.decode(Sponsors.self, from: data)
  }

  public func openSponsorLink(_ sponsor: Sponsor) {
    guard let url = sponsor.link else { return }
    #if os(iOS)
      // On iOS, this would open in Safari
      // Skip will handle this for Android
    #endif
    // For now, we'll just print the URL
    // In a real implementation, this would use platform-specific URL handling
    print("Opening URL: \(url)")
  }
}

enum SponsorError: Error, LocalizedError {
  case fileNotFound

  var errorDescription: String? {
    switch self {
    case .fileNotFound:
      return "Sponsors file not found"
    }
  }
}
