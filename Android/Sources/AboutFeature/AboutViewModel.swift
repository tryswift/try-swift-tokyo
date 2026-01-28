import Foundation
import Observation
import SharedModels

@Observable
public final class AboutViewModel {
  public var organizers: [Organizer] = []
  public var isLoading = false
  public var errorMessage: String?

  public init() {}

  public func loadOrganizers() {
    isLoading = true
    errorMessage = nil

    do {
      organizers = try loadOrganizersFromBundle()
    } catch {
      errorMessage = error.localizedDescription
    }

    isLoading = false
  }

  private func loadOrganizersFromBundle() throws -> [Organizer] {
    guard let url = Bundle.module.url(forResource: "2026-organizers", withExtension: "json") else {
      throw AboutError.fileNotFound
    }
    let data = try Data(contentsOf: url)
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
