import Dependencies
import DependenciesMacros
import Foundation

// MARK: - API Base URL

private let apiBaseURL = URL(string: "https://tryswift-cfp-api.fly.dev/api/v1")!

// MARK: - Device ID

enum DeviceIdentifier {
  private static let key = "tryswift_device_id"

  static var current: String {
    if let existing = UserDefaults.standard.string(forKey: key) {
      return existing
    }
    let new = UUID().uuidString
    UserDefaults.standard.set(new, forKey: key)
    return new
  }
}

// MARK: - Response Types

struct FavoriteItemResponse: Codable {
  let proposalId: UUID
}

struct FavoriteToggleResponse: Codable {
  let isFavorite: Bool
}

// MARK: - API Client

@DependencyClient
struct ScheduleAPIClient: Sendable {
  var fetchFavorites: @Sendable (_ deviceId: String) async throws -> [String] = { _ in [] }
  var toggleFavorite: @Sendable (_ proposalId: String, _ deviceId: String) async throws -> Bool = {
    _, _ in false
  }
  var submitFeedback: @Sendable (_ proposalId: String, _ comment: String, _ deviceId: String)
    async throws -> Void
}

extension DependencyValues {
  var scheduleAPIClient: ScheduleAPIClient {
    get { self[ScheduleAPIClient.self] }
    set { self[ScheduleAPIClient.self] = newValue }
  }
}

extension ScheduleAPIClient: DependencyKey {
  static let liveValue = ScheduleAPIClient(
    fetchFavorites: { deviceId in
      var components = URLComponents(url: apiBaseURL.appendingPathComponent("favorites"), resolvingAgainstBaseURL: false)!
      components.queryItems = [URLQueryItem(name: "deviceId", value: deviceId)]
      var request = URLRequest(url: components.url!)
      request.httpMethod = "GET"

      let (data, _) = try await URLSession.shared.data(for: request)
      let decoder = JSONDecoder()
      decoder.keyDecodingStrategy = .convertFromSnakeCase
      let items = try decoder.decode([FavoriteItemResponse].self, from: data)
      return items.map(\.proposalId.uuidString)
    },
    toggleFavorite: { proposalId, deviceId in
      let url = apiBaseURL.appendingPathComponent("favorites")
      var request = URLRequest(url: url)
      request.httpMethod = "PUT"
      request.setValue("application/json", forHTTPHeaderField: "Content-Type")

      let body: [String: String] = ["proposalId": proposalId, "deviceId": deviceId]
      request.httpBody = try JSONEncoder().encode(body)

      let (data, _) = try await URLSession.shared.data(for: request)
      let decoder = JSONDecoder()
      decoder.keyDecodingStrategy = .convertFromSnakeCase
      let response = try decoder.decode(FavoriteToggleResponse.self, from: data)
      return response.isFavorite
    },
    submitFeedback: { proposalId, comment, deviceId in
      let url = apiBaseURL.appendingPathComponent("feedback")
      var request = URLRequest(url: url)
      request.httpMethod = "POST"
      request.setValue("application/json", forHTTPHeaderField: "Content-Type")

      let body: [String: String] = [
        "proposalId": proposalId,
        "comment": comment,
        "deviceId": deviceId,
      ]
      request.httpBody = try JSONEncoder().encode(body)

      let (_, response) = try await URLSession.shared.data(for: request)
      guard let httpResponse = response as? HTTPURLResponse,
        (200...299).contains(httpResponse.statusCode)
      else {
        throw URLError(.badServerResponse)
      }
    }
  )

  static let testValue = ScheduleAPIClient()
}
