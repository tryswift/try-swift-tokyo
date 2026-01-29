import Foundation
import SharedModels
import SkipModel

public enum ScheduleDay: String, CaseIterable, Identifiable {
  case day1 = "Day 1"
  case day2 = "Day 2"
  case day3 = "Day 3"

  public var id: String { rawValue }
}

@Observable
public final class ScheduleViewModel {
  public var selectedDay: ScheduleDay = .day1
  public var day1: Conference?
  public var day2: Conference?
  public var day3: Conference?
  public var isLoading = false
  public var errorMessage: String?
  public var selectedSession: Session?

  public var currentConference: Conference? {
    switch selectedDay {
    case .day1: return day1
    case .day2: return day2
    case .day3: return day3
    }
  }

  public init() {}

  public func loadSchedules() {
    isLoading = true
    errorMessage = nil

    do {
      day1 = try loadConference(fileName: "2026-day1")
      day2 = try loadConference(fileName: "2026-day2")
      day3 = try loadConference(fileName: "2026-day3")
    } catch {
      errorMessage = error.localizedDescription
    }

    isLoading = false
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
