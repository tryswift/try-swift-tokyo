import Foundation
import Observation
import SharedModels

@Observable
public final class SponsorsViewModel {
  public var sponsors: Sponsors?
  public var isLoading = false
  public var errorMessage: String?

  public init() {}

  public func loadSponsors() {
    isLoading = true
    errorMessage = nil

    do {
      sponsors = try loadSponsorsFromBundle()
    } catch {
      errorMessage = error.localizedDescription
    }

    isLoading = false
  }

  private func loadSponsorsFromBundle() throws -> Sponsors {
    guard let url = Bundle.module.url(forResource: "2026-sponsors", withExtension: "json") else {
      throw SponsorError.fileNotFound
    }
    let data = try Data(contentsOf: url)
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
