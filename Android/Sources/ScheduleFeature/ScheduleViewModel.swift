import Foundation
import SharedModels
import SkipModel

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
