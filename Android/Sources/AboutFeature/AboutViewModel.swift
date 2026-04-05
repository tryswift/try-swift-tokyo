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
public final class AboutViewModel {
  public var organizers: [Organizer] = []
  public var isLoading = false
  public var errorMessage: String?
  public var selectedOrganizer: Organizer?

  public init() {}

  public func loadOrganizers() {
    guard organizers.isEmpty else { return }
    isLoading = true
    errorMessage = nil

    Task {
      do {
        organizers = try await loadOrganizersData()
      } catch {
        errorMessage = error.localizedDescription
      }
      isLoading = false
    }
  }

  private func loadOrganizersData() async throws -> [Organizer] {
    let data: Data
    if let url = Bundle.module.url(forResource: "2026-organizers", withExtension: "json") {
      data = try Data(contentsOf: url)
    } else if let assetBundle = androidAssetBundle(),
      let assetURL = assetBundle.url(forResource: "2026-organizers", withExtension: "json")
    {
      data = try Data(contentsOf: assetURL)
    } else if let remoteURL = URL(string: "\(resourceBaseURLString)/2026-organizers.json") {
      let (remoteData, _) = try await URLSession.shared.data(from: remoteURL)
      data = remoteData
    } else {
      throw AboutError.fileNotFound
    }

    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    return try decoder.decode([Organizer].self, from: data)
  }
}

enum AboutError: Error, LocalizedError {
  case fileNotFound

  var errorDescription: String? {
    switch self {
    case .fileNotFound:
      return "Organizers file not found"
    }
  }
}
