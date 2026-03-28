import ComposableArchitecture
import DataClient
import SharedModels
import Testing

@testable import ScheduleFeature

@Suite
@MainActor
struct ScheduleTests {

  /// A non-empty sentinel so the `allSessions.isEmpty` guard in onAppear
  /// skips the search-preload effect — keeping these tests focused on fetch behavior.
  static let preloadedSessions: [ScheduleFeature.Schedule.SearchableSession] = [
    .init(year: .year2026, session: .mock1, searchCorpus: "session1 speaker1")
  ]

  @Test
  func fetchData_success() async {
    var state = Schedule.State()
    state.allSessions = Self.preloadedSessions

    let store = TestStore(initialState: state) {
      Schedule()
    } withDependencies: {
      $0[DataClient.self].fetchDay1 = { @Sendable _ in .mock1 }
      $0[DataClient.self].fetchDay2 = { @Sendable _ in .mock2 }
      $0[DataClient.self].fetchDay3 = { @Sendable _ in .mock3 }
      $0[DataClient.self].fetchVideos = { @Sendable _ in [.mock1] }
    }
    await store.send(.view(.onAppear)) {
      $0.currentTime = $0.currentTime  // date dependency returns current date
    }
    await store.receive(\.fetchResponse.success) {
      $0.day1 = .mock1
      $0.day2 = .mock2
      $0.day3 = .mock3
      $0.videoMetadata = ["session1": .mock1]
    }
    await store.send(.view(.onDisappear))
  }

  @Test
  func fetchData_failure() async {
    struct FetchError: Equatable, Error {}

    var state = Schedule.State()
    state.allSessions = Self.preloadedSessions

    let store = TestStore(initialState: state) {
      Schedule()
    } withDependencies: {
      $0[DataClient.self].fetchDay1 = { @Sendable _ in throw FetchError() }
      $0[DataClient.self].fetchDay2 = { @Sendable _ in .mock2 }
      $0[DataClient.self].fetchDay3 = { @Sendable _ in .mock3 }
      $0[DataClient.self].fetchVideos = { @Sendable _ in [] }
    }
    await store.send(.view(.onAppear)) {
      $0.currentTime = $0.currentTime
    }
    await store.receive(\.fetchResponse.failure)
    await store.send(.view(.onDisappear))
  }

  @Test
  func fetchData_withoutDay3() async {
    struct NotFound: Equatable, Error {}

    var state = Schedule.State()
    state.allSessions = Self.preloadedSessions

    let store = TestStore(initialState: state) {
      Schedule()
    } withDependencies: {
      $0[DataClient.self].fetchDay1 = { @Sendable _ in .mock1 }
      $0[DataClient.self].fetchDay2 = { @Sendable _ in .mock2 }
      $0[DataClient.self].fetchDay3 = { @Sendable _ in throw NotFound() }
      $0[DataClient.self].fetchVideos = { @Sendable _ in [.mock1] }
    }
    await store.send(.view(.onAppear)) {
      $0.currentTime = $0.currentTime
    }
    await store.receive(\.fetchResponse.success) {
      $0.day1 = .mock1
      $0.day2 = .mock2
      $0.day3 = nil
      $0.videoMetadata = ["session1": .mock1]
    }
    await store.send(.view(.onDisappear))
  }

  @Test
  func yearSelected_switchesToNewYear() async {
    var state = Schedule.State()
    state.selectedYear = .year2026
    state.day1 = .mock1
    state.day2 = .mock2
    state.day3 = .mock3
    state.allSessions = Self.preloadedSessions

    let store = TestStore(initialState: state) {
      Schedule()
    } withDependencies: {
      $0[DataClient.self].fetchDay1 = { @Sendable _ in .mock1 }
      $0[DataClient.self].fetchDay2 = { @Sendable _ in .mock2 }
      $0[DataClient.self].fetchDay3 = { @Sendable _ in
        throw DataClientError.resourceNotFound("2017-day3")
      }
      $0[DataClient.self].fetchVideos = { @Sendable _ in [.mock1] }
    }

    await store.send(.view(.yearSelected(.year2017))) {
      $0.selectedYear = .year2017
      $0.selectedDay = .day1
      $0.day1 = nil
      $0.day2 = nil
      $0.day3 = nil
      $0.videoMetadata = [:]
    }
    await store.receive(\.view.onAppear) {
      $0.currentTime = $0.currentTime
    }
    await store.receive(\.fetchResponse.success) {
      $0.day1 = .mock1
      $0.day2 = .mock2
      $0.day3 = nil
      $0.videoMetadata = ["session1": .mock1]
    }
    await store.send(.view(.onDisappear))
  }

  @Test
  func allSessionsLoaded_onFirstAppear() async {
    let store = TestStore(initialState: Schedule.State()) {
      Schedule()
    } withDependencies: {
      $0[DataClient.self].fetchDay1 = { @Sendable _ in .mock1 }
      $0[DataClient.self].fetchDay2 = { @Sendable _ in .mock2 }
      $0[DataClient.self].fetchDay3 = { @Sendable _ in
        throw DataClientError.resourceNotFound("day3")
      }
      $0[DataClient.self].fetchVideos = { @Sendable _ in [.mock1] }
    }

    await store.send(.view(.onAppear)) {
      $0.currentTime = $0.currentTime
    }
    await store.receive(\.fetchResponse.success) {
      $0.day1 = .mock1
      $0.day2 = .mock2
      $0.day3 = nil
      $0.videoMetadata = ["session1": .mock1]
    }

    // Each year loads day1 (.mock1) and day2 (.mock2), day3 throws resourceNotFound.
    // Each conference mock has 2 sessions (mock1, mock2), both with description != nil.
    // 7 years × 2 days × 2 sessions = 28 SearchableSession entries.
    let expectedSessions: [ScheduleFeature.Schedule.SearchableSession] = ConferenceYear.allCases
      .flatMap { year in
        [Conference.mock1, .mock2].flatMap { conference in
          conference.schedules.flatMap { schedule in
            schedule.sessions.compactMap { session -> ScheduleFeature.Schedule.SearchableSession? in
              guard session.description != nil else { return nil }
              var parts: [String] = [session.title]
              if let speakers = session.speakers {
                parts.append(contentsOf: speakers.map(\.name))
              }
              return .init(
                year: year, session: session,
                searchCorpus: parts.joined(separator: " ").lowercased())
            }
          }
        }
      }

    await store.receive(\.allSessionsLoaded) {
      $0.allSessions = expectedSessions
    }
    await store.send(.view(.onDisappear))
  }

  @Test
  func searchResults_filtersByTitle() async {
    var state = Schedule.State()
    state.allSessions = [
      .init(year: .year2026, session: .mock1, searchCorpus: "session1 speaker1"),
      .init(year: .year2025, session: .mock2, searchCorpus: "session2 speaker2"),
    ]
    state.isSearchBarPresented = true
    state.searchText = "session1"

    #expect(state.searchResults.count == 1)
    #expect(state.searchResults.first?.session == .mock1)
    #expect(state.isShowingSearchResults == true)
  }

  @Test
  func searchResults_filtersBySpeakerName() async {
    var state = Schedule.State()
    state.allSessions = [
      .init(year: .year2026, session: .mock1, searchCorpus: "session1 speaker1"),
      .init(year: .year2025, session: .mock2, searchCorpus: "session2 speaker2"),
    ]
    state.isSearchBarPresented = true
    state.searchText = "speaker2"

    #expect(state.searchResults.count == 1)
    #expect(state.searchResults.first?.session == .mock2)
  }

  @Test
  func searchResults_emptyForNoMatch() async {
    var state = Schedule.State()
    state.allSessions = [
      .init(year: .year2026, session: .mock1, searchCorpus: "session1 speaker1")
    ]
    state.isSearchBarPresented = true
    state.searchText = "nonexistent"

    #expect(state.searchResults.isEmpty)
    #expect(state.isShowingSearchResults == true)
  }

  @Test
  func searchResults_caseInsensitive() async {
    var state = Schedule.State()
    state.allSessions = [
      .init(year: .year2026, session: .mock1, searchCorpus: "swift concurrency deep dive")
    ]
    state.isSearchBarPresented = true
    state.searchText = "SWIFT"

    #expect(state.searchResults.count == 1)
  }

  @Test
  func isShowingSearchResults_falseWhenSearchBarDismissed() async {
    var state = Schedule.State()
    state.allSessions = [
      .init(year: .year2026, session: .mock1, searchCorpus: "session1")
    ]
    state.isSearchBarPresented = false
    state.searchText = "session1"

    #expect(state.isShowingSearchResults == false)
  }

  @Test
  func isShowingSearchResults_falseWhenSearchTextEmpty() async {
    var state = Schedule.State()
    state.isSearchBarPresented = true
    state.searchText = ""

    #expect(state.isShowingSearchResults == false)
  }
}
