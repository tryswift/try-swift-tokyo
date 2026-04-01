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
      $0.videoMetadata = ["abc123def45": .mock1]
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
      $0.videoMetadata = ["abc123def45": .mock1]
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
      $0.videoMetadata = ["abc123def45": .mock1]
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
      $0.videoMetadata = ["abc123def45": .mock1]
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

  @Test
  func disclosureTapped_withVideo_richMetadata() async {
    var state = Schedule.State()
    state.allSessions = Self.preloadedSessions
    state.videoMetadata = ["abc123def45": .mock1]

    let store = TestStore(initialState: state) {
      Schedule()
    }

    await store.send(.view(.disclosureTapped(.mock1)))
    await store.receive(\.delegate.showVideoDetail)
  }

  @Test
  func disclosureTapped_withVideo_fallbackMetadata() async {
    var state = Schedule.State()
    state.allSessions = Self.preloadedSessions

    let store = TestStore(initialState: state) {
      Schedule()
    }

    await store.send(.view(.disclosureTapped(.mock1)))
    await store.receive(\.delegate.showVideoDetail)
  }

  @Test
  func disclosureTapped_withoutVideo() async {
    var state = Schedule.State()
    state.allSessions = Self.preloadedSessions

    let store = TestStore(initialState: state) {
      Schedule()
    }

    #if os(macOS)
      await store.send(.view(.disclosureTapped(.mock2)))
      await store.receive(
        .delegate(
          .showScheduleDetail(
            .mock2, proposalId: nil, isFavorite: false, favoriteCount: 0,
            relatedSessions: [], tagCandidates: [])))
    #else
      await store.send(.view(.disclosureTapped(.mock2))) {
        $0.path.append(
          .detail(
            ScheduleDetail.State(
              title: "session2",
              description: "description2",
              requirements: "requirements2",
              speakers: [.mock2]
            )))
      }
    #endif
  }

  #if os(macOS)
    @Test
    func disclosureTapped_withoutVideo_passesFavoriteState() async {
      var state = Schedule.State()
      state.allSessions = Self.preloadedSessions
      state.favoriteProposalIds = ["proposal-3"]
      state.favoriteCounts = ["proposal-3": 7]

      let store = TestStore(initialState: state) {
        Schedule()
      }

      await store.send(.view(.disclosureTapped(.mock3)))
      await store.receive(
        .delegate(
          .showScheduleDetail(
            .mock3, proposalId: "proposal-3", isFavorite: true, favoriteCount: 7,
            relatedSessions: [], tagCandidates: [])))
    }
  #endif

  // MARK: - Favorites

  @Test
  func favoritesLoaded_onAppear() async {
    var state = Schedule.State()
    state.allSessions = Self.preloadedSessions

    let store = TestStore(initialState: state) {
      Schedule()
    } withDependencies: {
      $0[DataClient.self].fetchDay1 = { @Sendable _ in .mock1 }
      $0[DataClient.self].fetchDay2 = { @Sendable _ in .mock2 }
      $0[DataClient.self].fetchDay3 = { @Sendable _ in
        throw DataClientError.resourceNotFound("day3")
      }
      $0.scheduleAPIClient.fetchFavorites = { @Sendable _ in ["proposal-1"] }
      $0.scheduleAPIClient.fetchFavoriteCounts = { @Sendable in ["proposal-1": 5] }
    }
    store.exhaustivity = .off

    await store.send(.view(.onAppear))
    await store.receive(\.favoritesLoaded) {
      $0.favoriteProposalIds = ["proposal-1"]
      $0.hasLoadedFavorites = true
    }
    await store.receive(\.favoriteCountsLoaded) {
      $0.favoriteCounts = ["proposal-1": 5]
    }
  }

  @Test
  func favoritesNotReloaded_whenAlreadyLoaded() async {
    var state = Schedule.State()
    state.allSessions = Self.preloadedSessions
    state.hasLoadedFavorites = true

    let store = TestStore(initialState: state) {
      Schedule()
    } withDependencies: {
      $0[DataClient.self].fetchDay1 = { @Sendable _ in .mock1 }
      $0[DataClient.self].fetchDay2 = { @Sendable _ in .mock2 }
      $0[DataClient.self].fetchDay3 = { @Sendable _ in
        throw DataClientError.resourceNotFound("day3")
      }
      $0.scheduleAPIClient.fetchFavoriteCounts = { @Sendable in [:] }
    }
    store.exhaustivity = .off

    await store.send(.view(.onAppear))
    await store.receive(\.fetchResponse.success) {
      $0.day1 = .mock1
      $0.day2 = .mock2
      $0.day3 = nil
    }
  }

  @Test
  func favoriteTapped_togglesAndReconciles() async {
    var state = Schedule.State()
    state.allSessions = Self.preloadedSessions
    state.hasLoadedFavorites = true
    state.favoriteProposalIds = []
    state.favoriteCounts = [:]

    let store = TestStore(initialState: state) {
      Schedule()
    } withDependencies: {
      $0.scheduleAPIClient.toggleFavorite = { @Sendable _, _ in (isFavorite: true, count: 1) }
    }

    await store.send(.view(.favoriteTapped(.mock1))) {
      $0.favoriteProposalIds = ["proposal-1"]
    }
    await store.receive(\.favoriteToggled) {
      $0.favoriteProposalIds = ["proposal-1"]
      $0.favoriteCounts = ["proposal-1": 1]
    }
  }

  @Test
  func favoriteTapped_revertsOnError() async {
    struct ToggleError: Error {}

    var state = Schedule.State()
    state.allSessions = Self.preloadedSessions
    state.hasLoadedFavorites = true
    state.favoriteProposalIds = ["proposal-1"]
    state.favoriteCounts = ["proposal-1": 3]

    let store = TestStore(initialState: state) {
      Schedule()
    } withDependencies: {
      $0.scheduleAPIClient.toggleFavorite = { @Sendable _, _ in throw ToggleError() }
    }

    await store.send(.view(.favoriteTapped(.mock1))) {
      $0.favoriteProposalIds = []
    }
    await store.receive(\.favoriteToggled) {
      $0.favoriteProposalIds = ["proposal-1"]
      $0.favoriteCounts = ["proposal-1": 3]
    }
  }

  // MARK: - Related Sessions

  @Test
  func findRelatedSessions_sameSpeakerAlwaysIncluded_evenWithNoTagOverlap() {
    // session1 (speaker1) and session3 (speaker1) share no tags, but share a speaker
    let allSessions: [Schedule.SearchableSession] = [
      .init(year: .year2026, session: .mock1, searchCorpus: "session1 speaker1"),
      .init(year: .year2025, session: .mock3, searchCorpus: "session3 speaker1"),
    ]

    let results = Schedule.findRelatedSessions(for: .mock1, from: allSessions)
    #expect(results.count == 1)
    #expect(results[0].session == .mock3)
    #expect(results[0].isSameSpeaker == true)
  }

  @Test
  func findRelatedSessions_sameSpeakerSorted_newestFirst() {
    let sessionA = Session(
      title: "talk-a", speakers: [.mock1], place: "p", description: "desc-a")
    let sessionB = Session(
      title: "talk-b", speakers: [.mock1], place: "p", description: "desc-b")
    let sessionC = Session(
      title: "talk-c", speakers: [.mock1], place: "p", description: "desc-c")

    let allSessions: [Schedule.SearchableSession] = [
      .init(year: .year2026, session: .mock1, searchCorpus: "session1"),
      .init(year: .year2016, session: sessionA, searchCorpus: "talk-a"),
      .init(year: .year2019, session: sessionB, searchCorpus: "talk-b"),
      .init(year: .year2025, session: sessionC, searchCorpus: "talk-c"),
    ]

    let results = Schedule.findRelatedSessions(for: .mock1, from: allSessions)
    #expect(results.count == 3)
    #expect(results[0].year == .year2025)
    #expect(results[1].year == .year2019)
    #expect(results[2].year == .year2016)
  }

  @Test
  func findRelatedSessions_tagMatchedFillsRemaining_afterSameSpeaker() {
    // "SwiftUI" in title triggers the .swiftUI tag
    let swiftuiSession = Session(
      title: "Advanced SwiftUI Techniques",
      speakers: [.mock1], place: "p", description: "Building complex SwiftUI views")
    let tagMatchSession = Session(
      title: "SwiftUI Performance Tips",
      speakers: [.mock2], place: "p", description: "Optimizing SwiftUI apps")

    let allSessions: [Schedule.SearchableSession] = [
      .init(year: .year2026, session: swiftuiSession, searchCorpus: "swiftui"),
      .init(year: .year2025, session: .mock3, searchCorpus: "session3"),
      .init(year: .year2025, session: tagMatchSession, searchCorpus: "swiftui"),
    ]

    let results = Schedule.findRelatedSessions(for: swiftuiSession, from: allSessions)

    // mock3 shares speaker1 → same-speaker first; tagMatchSession matches SwiftUI tag
    let sameSpeaker = results.filter(\.isSameSpeaker)
    let tagMatched = results.filter { !$0.isSameSpeaker }
    #expect(!sameSpeaker.isEmpty)
    #expect(!tagMatched.isEmpty)
    // Same-speaker comes before tag-matched
    let firstSameSpeakerIdx = results.firstIndex(where: \.isSameSpeaker)!
    let firstTagIdx = results.firstIndex(where: { !$0.isSameSpeaker })!
    #expect(firstSameSpeakerIdx < firstTagIdx)
  }

  @Test
  func findRelatedSessions_limitRespected() {
    var allSessions: [Schedule.SearchableSession] = [
      .init(year: .year2026, session: .mock1, searchCorpus: "session1")
    ]
    // Add 6 same-speaker sessions across different years
    for (i, year) in
      [ConferenceYear.year2016, .year2017, .year2018, .year2019, .year2020, .year2025].enumerated()
    {
      let s = Session(
        title: "talk-\(i)", speakers: [.mock1], place: "p", description: "desc-\(i)")
      allSessions.append(.init(year: year, session: s, searchCorpus: "talk-\(i)"))
    }

    let results = Schedule.findRelatedSessions(for: .mock1, from: allSessions)
    #expect(results.count == 5)
    // Should be newest first
    #expect(results[0].year == .year2025)
    #expect(results[1].year == .year2020)
  }
}
