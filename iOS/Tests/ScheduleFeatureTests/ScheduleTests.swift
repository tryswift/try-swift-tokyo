import ComposableArchitecture
import DataClient
import SharedModels
import Testing
import VideoFeature

@testable import ScheduleFeature

typealias ScheduleReducer = ScheduleFeature.Schedule

@Suite
@MainActor
struct ScheduleTests {

  /// A non-empty sentinel so the `allSessions.isEmpty` guard in onAppear
  /// skips the search-preload effect — keeping these tests focused on fetch behavior.
  static let preloadedSessions: [ScheduleReducer.SearchableSession] = [
    .init(year: .year2026, session: .mock1, searchCorpus: "session1 speaker1")
  ]

  @Test
  func fetchData_success() async {
    var state = ScheduleReducer.State()
    state.allSessions = Self.preloadedSessions

    let store = TestStore(initialState: state) {
      ScheduleReducer()
    } withDependencies: {
      $0[DataClient.self].fetchDay1 = { @Sendable _ in .mock1 }
      $0[DataClient.self].fetchDay2 = { @Sendable _ in .mock2 }
      $0[DataClient.self].fetchDay3 = { @Sendable _ in .mock3 }
      $0[DataClient.self].fetchVideos = { @Sendable _ in [.mock1] }
      $0[DataClient.self].fetchWorkshop = { @Sendable _ in
        throw DataClientError.resourceNotFound("workshop")
      }
      $0.scheduleAPIClient.fetchFavorites = { @Sendable _ in [] }
      $0.scheduleAPIClient.fetchFavoriteCounts = { @Sendable in [:] }
      $0.date = .constant(Date(timeIntervalSince1970: 0))
      $0.continuousClock = ImmediateClock()
    }
    store.exhaustivity = .off

    await store.send(.view(.onAppear))
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

    var state = ScheduleReducer.State()
    state.allSessions = Self.preloadedSessions

    let store = TestStore(initialState: state) {
      ScheduleReducer()
    } withDependencies: {
      $0[DataClient.self].fetchDay1 = { @Sendable _ in throw FetchError() }
      $0[DataClient.self].fetchDay2 = { @Sendable _ in .mock2 }
      $0[DataClient.self].fetchDay3 = { @Sendable _ in .mock3 }
      $0[DataClient.self].fetchVideos = { @Sendable _ in [] }
      $0[DataClient.self].fetchWorkshop = { @Sendable _ in
        throw DataClientError.resourceNotFound("workshop")
      }
      $0.scheduleAPIClient.fetchFavorites = { @Sendable _ in [] }
      $0.scheduleAPIClient.fetchFavoriteCounts = { @Sendable in [:] }
      $0.date = .constant(Date(timeIntervalSince1970: 0))
      $0.continuousClock = ImmediateClock()
    }
    store.exhaustivity = .off

    await store.send(.view(.onAppear))
    await store.receive(\.fetchResponse.failure)
    await store.send(.view(.onDisappear))
  }

  @Test
  func fetchData_withoutDay3() async {
    var state = ScheduleReducer.State()
    state.allSessions = Self.preloadedSessions

    let store = TestStore(initialState: state) {
      ScheduleReducer()
    } withDependencies: {
      $0[DataClient.self].fetchDay1 = { @Sendable _ in .mock1 }
      $0[DataClient.self].fetchDay2 = { @Sendable _ in .mock2 }
      $0[DataClient.self].fetchDay3 = { @Sendable _ in
        throw DataClientError.resourceNotFound("day3")
      }
      $0[DataClient.self].fetchVideos = { @Sendable _ in [.mock1] }
      $0[DataClient.self].fetchWorkshop = { @Sendable _ in
        throw DataClientError.resourceNotFound("workshop")
      }
      $0.scheduleAPIClient.fetchFavorites = { @Sendable _ in [] }
      $0.scheduleAPIClient.fetchFavoriteCounts = { @Sendable in [:] }
      $0.date = .constant(Date(timeIntervalSince1970: 0))
      $0.continuousClock = ImmediateClock()
    }
    store.exhaustivity = .off

    await store.send(.view(.onAppear))
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
    var state = ScheduleReducer.State()
    state.selectedYear = .year2026
    state.day1 = .mock1
    state.day2 = .mock2
    state.day3 = .mock3
    state.allSessions = Self.preloadedSessions

    let store = TestStore(initialState: state) {
      ScheduleReducer()
    } withDependencies: {
      $0[DataClient.self].fetchDay1 = { @Sendable _ in .mock1 }
      $0[DataClient.self].fetchDay2 = { @Sendable _ in .mock2 }
      $0[DataClient.self].fetchDay3 = { @Sendable _ in
        throw DataClientError.resourceNotFound("2017-day3")
      }
      $0[DataClient.self].fetchVideos = { @Sendable _ in [.mock1] }
      $0[DataClient.self].fetchWorkshop = { @Sendable _ in
        throw DataClientError.resourceNotFound("workshop")
      }
      $0.scheduleAPIClient.fetchFavorites = { @Sendable _ in [] }
      $0.scheduleAPIClient.fetchFavoriteCounts = { @Sendable in [:] }
      $0.date = .constant(Date(timeIntervalSince1970: 0))
      $0.continuousClock = ImmediateClock()
    }
    store.exhaustivity = .off

    await store.send(.view(.yearSelected(.year2017))) {
      $0.selectedYear = .year2017
      $0.selectedDay = .day1
      $0.day1 = nil
      $0.day2 = nil
      $0.day3 = nil
      $0.videoMetadata = [:]
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
    let store = TestStore(initialState: ScheduleReducer.State()) {
      ScheduleReducer()
    } withDependencies: {
      $0[DataClient.self].fetchDay1 = { @Sendable _ in .mock1 }
      $0[DataClient.self].fetchDay2 = { @Sendable _ in .mock2 }
      $0[DataClient.self].fetchDay3 = { @Sendable _ in
        throw DataClientError.resourceNotFound("day3")
      }
      $0[DataClient.self].fetchVideos = { @Sendable _ in [.mock1] }
      $0[DataClient.self].fetchWorkshop = { @Sendable _ in
        throw DataClientError.resourceNotFound("workshop")
      }
      $0.scheduleAPIClient.fetchFavorites = { @Sendable _ in [] }
      $0.scheduleAPIClient.fetchFavoriteCounts = { @Sendable in [:] }
      $0.date = .constant(Date(timeIntervalSince1970: 0))
      $0.continuousClock = ImmediateClock()
    }
    store.exhaustivity = .off

    await store.send(.view(.onAppear))
    await store.receive(\.fetchResponse.success) {
      $0.day1 = .mock1
      $0.day2 = .mock2
      $0.day3 = nil
      $0.videoMetadata = ["abc123def45": .mock1]
    }

    let expectedSessions: [ScheduleReducer.SearchableSession] = ConferenceYear.allCases
      .flatMap { year in
        [Conference.mock1, .mock2].flatMap { conference in
          conference.schedules.flatMap { schedule in
            schedule.sessions.compactMap { session -> ScheduleReducer.SearchableSession? in
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
    var state = ScheduleReducer.State()
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
    var state = ScheduleReducer.State()
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
    var state = ScheduleReducer.State()
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
    var state = ScheduleReducer.State()
    state.allSessions = [
      .init(year: .year2026, session: .mock1, searchCorpus: "swift concurrency deep dive")
    ]
    state.isSearchBarPresented = true
    state.searchText = "SWIFT"

    #expect(state.searchResults.count == 1)
  }

  @Test
  func isShowingSearchResults_falseWhenSearchBarDismissed() async {
    var state = ScheduleReducer.State()
    state.allSessions = [
      .init(year: .year2026, session: .mock1, searchCorpus: "session1")
    ]
    state.isSearchBarPresented = false
    state.searchText = "session1"

    #expect(state.isShowingSearchResults == false)
  }

  @Test
  func isShowingSearchResults_falseWhenSearchTextEmpty() async {
    var state = ScheduleReducer.State()
    state.isSearchBarPresented = true
    state.searchText = ""

    #expect(state.isShowingSearchResults == false)
  }

  @Test
  func disclosureTapped_withVideo_richMetadata() async {
    var state = ScheduleReducer.State()
    state.allSessions = Self.preloadedSessions
    state.videoMetadata = ["abc123def45": .mock1]

    let store = TestStore(initialState: state) {
      ScheduleReducer()
    }

    #if os(macOS)
      await store.send(.view(.disclosureTapped(.mock1)))
      await store.receive(\.delegate.showVideoDetail)
    #elseif os(visionOS)
      await store.send(.view(.disclosureTapped(.mock1))) {
        $0.destination = .videoDetail(
          VideoDetail.State(
            session: .mock1, videoMetadata: .mock1,
            conferenceYear: .year2026))
      }
    #else
      await store.send(.view(.disclosureTapped(.mock1))) {
        $0.path.append(
          .videoDetail(
            VideoDetail.State(
              session: .mock1, videoMetadata: .mock1,
              conferenceYear: .year2026)))
      }
    #endif
  }

  @Test
  func disclosureTapped_withVideo_fallbackMetadata() async {
    var state = ScheduleReducer.State()
    state.allSessions = Self.preloadedSessions

    let store = TestStore(initialState: state) {
      ScheduleReducer()
    }

    let fallbackMetadata = VideoMetadata(
      sessionTitle: "session1", youtubeVideoId: "abc123def45")

    #if os(macOS)
      await store.send(.view(.disclosureTapped(.mock1)))
      await store.receive(\.delegate.showVideoDetail)
    #elseif os(visionOS)
      await store.send(.view(.disclosureTapped(.mock1))) {
        $0.destination = .videoDetail(
          VideoDetail.State(
            session: .mock1, videoMetadata: fallbackMetadata,
            conferenceYear: .year2026))
      }
    #else
      await store.send(.view(.disclosureTapped(.mock1))) {
        $0.path.append(
          .videoDetail(
            VideoDetail.State(
              session: .mock1, videoMetadata: fallbackMetadata,
              conferenceYear: .year2026)))
      }
    #endif
  }

  @Test
  func disclosureTapped_withoutVideo() async {
    var state = ScheduleReducer.State()
    state.allSessions = Self.preloadedSessions

    let store = TestStore(initialState: state) {
      ScheduleReducer()
    }

    #if os(macOS)
      await store.send(.view(.disclosureTapped(.mock2)))
      await store.receive(\.delegate.showScheduleDetail)
    #elseif os(visionOS)
      await store.send(.view(.disclosureTapped(.mock2))) {
        $0.destination = .detail(
          ScheduleDetail.State(
            title: "session2",
            description: "description2",
            requirements: "requirements2",
            speakers: [.mock2]
          ))
      }
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
      var state = ScheduleReducer.State()
      state.allSessions = Self.preloadedSessions
      state.favoriteProposalIds = ["proposal-3"]
      state.favoriteCounts = ["proposal-3": 7]

      let store = TestStore(initialState: state) {
        ScheduleReducer()
      }

      await store.send(.view(.disclosureTapped(.mock3)))
      await store.receive(\.delegate.showScheduleDetail)
    }
  #endif

  // MARK: - Favorites

  @Test
  func favoritesLoaded_onAppear() async {
    var state = ScheduleReducer.State()
    state.allSessions = Self.preloadedSessions

    let store = TestStore(initialState: state) {
      ScheduleReducer()
    } withDependencies: {
      $0[DataClient.self].fetchDay1 = { @Sendable _ in .mock1 }
      $0[DataClient.self].fetchDay2 = { @Sendable _ in .mock2 }
      $0[DataClient.self].fetchDay3 = { @Sendable _ in
        throw DataClientError.resourceNotFound("day3")
      }
      $0[DataClient.self].fetchVideos = { @Sendable _ in [.mock1] }
      $0[DataClient.self].fetchWorkshop = { @Sendable _ in
        throw DataClientError.resourceNotFound("workshop")
      }
      $0.scheduleAPIClient.fetchFavorites = { @Sendable _ in ["proposal-1"] }
      $0.scheduleAPIClient.fetchFavoriteCounts = { @Sendable in ["proposal-1": 5] }
      $0.date = .constant(Date(timeIntervalSince1970: 0))
      $0.continuousClock = ImmediateClock()
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
    var state = ScheduleReducer.State()
    state.allSessions = Self.preloadedSessions
    state.hasLoadedFavorites = true

    let store = TestStore(initialState: state) {
      ScheduleReducer()
    } withDependencies: {
      $0[DataClient.self].fetchDay1 = { @Sendable _ in .mock1 }
      $0[DataClient.self].fetchDay2 = { @Sendable _ in .mock2 }
      $0[DataClient.self].fetchDay3 = { @Sendable _ in
        throw DataClientError.resourceNotFound("day3")
      }
      $0[DataClient.self].fetchVideos = { @Sendable _ in [.mock1] }
      $0[DataClient.self].fetchWorkshop = { @Sendable _ in
        throw DataClientError.resourceNotFound("workshop")
      }
      $0.scheduleAPIClient.fetchFavoriteCounts = { @Sendable in [:] }
      $0.date = .constant(Date(timeIntervalSince1970: 0))
      $0.continuousClock = ImmediateClock()
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
    var state = ScheduleReducer.State()
    state.allSessions = Self.preloadedSessions
    state.hasLoadedFavorites = true
    state.favoriteProposalIds = []
    state.favoriteCounts = [:]

    let store = TestStore(initialState: state) {
      ScheduleReducer()
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

    var state = ScheduleReducer.State()
    state.allSessions = Self.preloadedSessions
    state.hasLoadedFavorites = true
    state.favoriteProposalIds = ["proposal-1"]
    state.favoriteCounts = ["proposal-1": 3]

    let store = TestStore(initialState: state) {
      ScheduleReducer()
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
    let allSessions: [ScheduleReducer.SearchableSession] = [
      .init(year: .year2026, session: .mock1, searchCorpus: "session1 speaker1"),
      .init(year: .year2025, session: .mock3, searchCorpus: "session3 speaker1"),
    ]

    let results = ScheduleReducer.findRelatedSessions(for: .mock1, from: allSessions)
    #expect(results.count == 1)
    #expect(results[0].session == .mock3)
    #expect(results[0].isSameSpeaker == true)
  }

  @Test
  func findRelatedSessions_sameSpeakerSorted_newestFirst() {
    let sessionA = Session(
      title: "talk-a", speakers: [.mock1], place: "p", description: "desc-a", requirements: nil)
    let sessionB = Session(
      title: "talk-b", speakers: [.mock1], place: "p", description: "desc-b", requirements: nil)
    let sessionC = Session(
      title: "talk-c", speakers: [.mock1], place: "p", description: "desc-c", requirements: nil)

    let allSessions: [ScheduleReducer.SearchableSession] = [
      .init(year: .year2026, session: .mock1, searchCorpus: "session1"),
      .init(year: .year2016, session: sessionA, searchCorpus: "talk-a"),
      .init(year: .year2019, session: sessionB, searchCorpus: "talk-b"),
      .init(year: .year2025, session: sessionC, searchCorpus: "talk-c"),
    ]

    let results = ScheduleReducer.findRelatedSessions(for: .mock1, from: allSessions)
    #expect(results.count == 3)
    #expect(results[0].year == .year2025)
    #expect(results[1].year == .year2019)
    #expect(results[2].year == .year2016)
  }

  @Test
  func findRelatedSessions_tagMatchedFillsRemaining_afterSameSpeaker() {
    let swiftuiSession = Session(
      title: "Advanced SwiftUI Techniques",
      speakers: [.mock1], place: "p", description: "Building complex SwiftUI views",
      requirements: nil)
    let tagMatchSession = Session(
      title: "SwiftUI Performance Tips",
      speakers: [.mock2], place: "p", description: "Optimizing SwiftUI apps",
      requirements: nil)

    let allSessions: [ScheduleReducer.SearchableSession] = [
      .init(year: .year2026, session: swiftuiSession, searchCorpus: "swiftui"),
      .init(year: .year2025, session: .mock3, searchCorpus: "session3"),
      .init(year: .year2025, session: tagMatchSession, searchCorpus: "swiftui"),
    ]

    let results = ScheduleReducer.findRelatedSessions(for: swiftuiSession, from: allSessions)

    let sameSpeaker = results.filter(\.isSameSpeaker)
    let tagMatched = results.filter { !$0.isSameSpeaker }
    #expect(!sameSpeaker.isEmpty)
    #expect(!tagMatched.isEmpty)
    let firstSameSpeakerIdx = results.firstIndex(where: \.isSameSpeaker)!
    let firstTagIdx = results.firstIndex(where: { !$0.isSameSpeaker })!
    #expect(firstSameSpeakerIdx < firstTagIdx)
  }

  @Test
  func findRelatedSessions_limitRespected() {
    var allSessions: [ScheduleReducer.SearchableSession] = [
      .init(year: .year2026, session: .mock1, searchCorpus: "session1")
    ]
    for (i, year) in [
      ConferenceYear.year2016, .year2017, .year2018, .year2019, .year2020, .year2025,
    ].enumerated() {
      let s = Session(
        title: "talk-\(i)", speakers: [.mock1], place: "p", description: "desc-\(i)",
        requirements: nil)
      allSessions.append(.init(year: year, session: s, searchCorpus: "talk-\(i)"))
    }

    let results = ScheduleReducer.findRelatedSessions(for: .mock1, from: allSessions)
    #expect(results.count == 5)
    #expect(results[0].year == .year2025)
    #expect(results[1].year == .year2020)
  }
}
