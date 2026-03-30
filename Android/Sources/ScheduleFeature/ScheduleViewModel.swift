import Foundation
import SharedModels
import SkipModel

// MARK: - API Configuration

private let apiBaseURLString = "https://tryswift-cfp-api.fly.dev/api/v1"

// MARK: - Device Identifier

enum AndroidDeviceIdentifier {
  private static let key = "tryswift_device_id"

  static var current: String {
    if let existing = UserDefaults.standard.string(forKey: key) {
      return existing
    }
    let newId = UUID().uuidString
    UserDefaults.standard.set(newId, forKey: key)
    return newId
  }
}

// MARK: - Schedule Day

public enum ScheduleDay: String, CaseIterable, Identifiable {
  case day1 = "Day 1"
  case day2 = "Day 2"
  case day3 = "Day 3"

  public var id: String { rawValue }
}

public struct SearchableSession: Equatable, Hashable {
  public let year: Int
  public let session: Session
  public let searchCorpus: String

  public static func == (lhs: SearchableSession, rhs: SearchableSession) -> Bool {
    lhs.year == rhs.year && lhs.session == rhs.session
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(year)
    hasher.combine(session)
  }
}

// MARK: - API Response Types

private struct FavoriteItemResponse: Codable {
  let proposalId: String
}

private struct FavoriteToggleResponse: Codable {
  let isFavorite: Bool
  let count: Int
}

private struct FavoriteCountItemResponse: Codable {
  let proposalId: String
  let count: Int
}

// MARK: - ViewModel

@Observable
@MainActor
public final class ScheduleViewModel {
  public var selectedDay: ScheduleDay = .day1
  public var selectedYear: Int = ConferenceYear.latest.rawValue
  public var day1: Conference?
  public var day2: Conference?
  public var day3: Conference?
  public var isLoading = false
  public var errorMessage: String?
  public var selectedSession: Session?
  public var searchText: String = ""
  public var isSearchBarPresented: Bool = false
  public var allSearchableSessions: [SearchableSession] = []
  public var currentTime: Date = Date()
  private var timerTask: Task<Void, Never>?

  // Favorites
  public var favoriteProposalIds: Set<String> = []
  public var favoriteCounts: [String: Int] = [:]

  // Feedback
  public var feedbackText: String = ""
  public var feedbackSubmitted: Bool = false
  public var isSubmittingFeedback: Bool = false
  public var feedbackError: String?

  public static let availableYears: [Int] = ConferenceYear.allCases.map { $0.rawValue }.reversed()

  public var currentConference: Conference? {
    switch selectedDay {
    case .day1: return day1
    case .day2: return day2
    case .day3: return day3
    }
  }

  public var hasDay3: Bool {
    day3 != nil
  }

  public var liveScheduleIndex: Int? {
    currentConference?.liveScheduleIndex(at: currentTime)
  }

  public var searchResults: [SearchableSession] {
    let query = searchText.lowercased()
      .trimmingCharacters(in: CharacterSet.whitespaces)
    guard !query.isEmpty else { return [] }
    var results: [SearchableSession] = []
    for s in allSearchableSessions {
      if s.searchCorpus.contains(query) {
        results.append(s)
      }
    }
    return results
  }

  public var isShowingSearchResults: Bool {
    isSearchBarPresented
      && !searchText.trimmingCharacters(in: CharacterSet.whitespaces).isEmpty
  }

  public init() {}

  public func loadSchedules() {
    isLoading = true
    errorMessage = nil

    do {
      day1 = try loadConference(fileName: "\(selectedYear)-day1")
      day2 = try? loadConference(fileName: "\(selectedYear)-day2")
      day3 = try? loadConference(fileName: "\(selectedYear)-day3")
    } catch {
      errorMessage = error.localizedDescription
    }

    isLoading = false
    startTimer()
  }

  private func startTimer() {
    timerTask?.cancel()
    timerTask = Task { [weak self] in
      while !Task.isCancelled {
        try? await Task.sleep(nanoseconds: 30_000_000_000)
        guard let self else { break }
        self.currentTime = Date()
      }
    }
  }

  public func selectYear(_ year: Int) {
    selectedYear = year
    selectedDay = .day1
    day1 = nil
    day2 = nil
    day3 = nil
    loadSchedules()
  }

  public func loadAllSessions() {
    guard allSearchableSessions.isEmpty else { return }
    var results: [SearchableSession] = []
    for year in ScheduleViewModel.availableYears {
      for dayNum in 1...3 {
        let fileName = "\(year)-day\(dayNum)"
        guard let conference = try? loadConference(fileName: fileName) else { continue }
        for schedule in conference.schedules {
          for session in schedule.sessions {
            guard session.description != nil else { continue }
            let corpus = ScheduleViewModel.buildSearchCorpus(session: session)
            results.append(
              SearchableSession(
                year: year, session: session, searchCorpus: corpus))
          }
        }
      }
    }
    allSearchableSessions = results
  }

  // MARK: - Favorites

  public func loadFavorites() {
    Task {
      do {
        guard
          let url = URL(
            string: "\(apiBaseURLString)/favorites?deviceId=\(AndroidDeviceIdentifier.current)")
        else { return }
        let request = URLRequest(url: url)
        let (data, _) = try await URLSession.shared.data(for: request)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let items = try decoder.decode([FavoriteItemResponse].self, from: data)
        var ids: Set<String> = []
        for item in items {
          ids.insert(item.proposalId)
        }
        self.favoriteProposalIds = ids
      } catch {
        // Silently fail - favorites are not critical
      }
    }
    loadFavoriteCounts()
  }

  public func loadFavoriteCounts() {
    Task {
      do {
        guard let url = URL(string: "\(apiBaseURLString)/favorite-counts") else { return }
        let request = URLRequest(url: url)
        let (data, _) = try await URLSession.shared.data(for: request)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let items = try decoder.decode([FavoriteCountItemResponse].self, from: data)
        var counts: [String: Int] = [:]
        for item in items {
          counts[item.proposalId] = item.count
        }
        self.favoriteCounts = counts
      } catch {
        // Silently fail
      }
    }
  }

  public func toggleFavorite(proposalId: String) {
    // Optimistic toggle
    if favoriteProposalIds.contains(proposalId) {
      favoriteProposalIds.remove(proposalId)
    } else {
      favoriteProposalIds.insert(proposalId)
    }

    Task {
      do {
        guard let url = URL(string: "\(apiBaseURLString)/favorites") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: String] = [
          "proposalId": proposalId, "deviceId": AndroidDeviceIdentifier.current,
        ]
        request.httpBody = try JSONEncoder().encode(body)

        let (data, _) = try await URLSession.shared.data(for: request)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let response = try decoder.decode(FavoriteToggleResponse.self, from: data)
        if response.isFavorite {
          self.favoriteProposalIds.insert(proposalId)
        } else {
          self.favoriteProposalIds.remove(proposalId)
        }
        self.favoriteCounts[proposalId] = response.count
      } catch {
        // Revert on failure
        if self.favoriteProposalIds.contains(proposalId) {
          self.favoriteProposalIds.remove(proposalId)
        } else {
          self.favoriteProposalIds.insert(proposalId)
        }
      }
    }
  }

  public func isFavorite(proposalId: String?) -> Bool {
    guard let proposalId = proposalId else { return false }
    return favoriteProposalIds.contains(proposalId)
  }

  public func favoriteCount(proposalId: String?) -> Int {
    guard let proposalId = proposalId else { return 0 }
    return favoriteCounts[proposalId] ?? 0
  }

  // MARK: - Feedback

  public func submitFeedback(proposalId: String) {
    let comment = feedbackText.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    guard !comment.isEmpty else { return }

    isSubmittingFeedback = true
    feedbackError = nil

    Task {
      do {
        guard let url = URL(string: "\(apiBaseURLString)/feedback") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: String] = [
          "proposalId": proposalId,
          "comment": comment,
          "deviceId": AndroidDeviceIdentifier.current,
        ]
        request.httpBody = try JSONEncoder().encode(body)

        let (_, response) = try await URLSession.shared.data(for: request)
        if let httpResponse = response as? HTTPURLResponse,
          (200...299).contains(httpResponse.statusCode)
        {
          self.feedbackSubmitted = true
          self.feedbackText = ""
        } else {
          self.feedbackError = "Failed to submit feedback"
        }
      } catch {
        self.feedbackError = error.localizedDescription
      }
      self.isSubmittingFeedback = false
    }
  }

  public func resetFeedbackState() {
    feedbackText = ""
    feedbackSubmitted = false
    feedbackError = nil
    isSubmittingFeedback = false
  }

  // MARK: - Private

  private static func buildSearchCorpus(session: Session) -> String {
    var parts: [String] = [session.title]
    if let titleJa = session.titleJa { parts.append(titleJa) }
    if let summary = session.summary { parts.append(summary) }
    if let summaryJa = session.summaryJa { parts.append(summaryJa) }
    if let speakers = session.speakers {
      for speaker in speakers {
        parts.append(speaker.name)
      }
    }
    return parts.joined(separator: " ").lowercased()
  }

  private func loadConference(fileName: String) throws -> Conference {
    guard let url = Bundle.module.url(forResource: fileName, withExtension: "json") else {
      throw DataError.fileNotFound(fileName)
    }
    let data = try Data(contentsOf: url)
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    return try decoder.decode(Conference.self, from: data)
  }

  public func selectSession(_ session: Session) {
    selectedSession = session
  }

  public func clearSelection() {
    selectedSession = nil
  }
}

enum DataError: Error, LocalizedError {
  case fileNotFound(String)

  var errorDescription: String? {
    switch self {
    case .fileNotFound(let name):
      return "File not found: \(name)"
    }
  }
}
