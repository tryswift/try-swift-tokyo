import ComposableArchitecture
import DataClient
import DependencyExtra
import Foundation
import SharedModels
import SwiftUI
import TipKit
import os

private let logger = Logger(subsystem: "jp.tryswift.tokyo.App", category: "Schedule")

@Reducer
public struct Schedule {
  public enum Days: LocalizedStringKey, Equatable, CaseIterable, Identifiable, Sendable {
    case day1 = "Day 1"
    case day2 = "Day 2"
    case day3 = "Day 3"

    public var id: Self { self }
  }

  public struct SchedulesResponse: Equatable {
    var day1: Conference
    var day2: Conference
    var day3: Conference?
    var videos: [VideoMetadata]
  }

  public struct SearchableSession: Equatable, Hashable {
    var year: ConferenceYear
    var session: Session
    var searchCorpus: String
  }

  @ObservableState
  public struct State: Equatable {

    var path = StackState<Path.State>()
    var selectedYear: ConferenceYear = .latest
    var selectedDay: Days = .day1
    var searchText: String = ""
    var isSearchBarPresented: Bool = false
    public var allSessions: [SearchableSession] = []
    var day1: Conference?
    var day2: Conference?
    var day3: Conference?
    public var favoriteProposalIds: Set<String> = []
    public var favoriteCounts: [String: Int] = [:]
    var hasLoadedFavorites: Bool = false
    public var videoMetadata: [String: VideoMetadata] = [:]
    var currentTime: Date = .distantPast
    @Presents var destination: Destination.State?

    var liveScheduleIndex: Int? {
      guard selectedYear == .latest else { return nil }
      let conference: Conference? =
        switch selectedDay {
        case .day1: day1
        case .day2: day2
        case .day3: day3
        }
      return conference?.liveScheduleIndex(at: currentTime)
    }

    public init() {}
  }

  public enum Action: BindableAction, ViewAction {
    case binding(BindingAction<State>)
    case path(StackAction<Path.State, Path.Action>)
    case destination(PresentationAction<Destination.Action>)
    case view(View)
    case fetchResponse(Result<SchedulesResponse, Error>)
    case allSessionsLoaded([SearchableSession])
    case favoritesLoaded(Set<String>)
    case favoriteCountsLoaded([String: Int])
    case favoriteToggled(String, Bool, Int)
    case delegate(Delegate)
    case timerTicked

    @CasePathable
    public enum View {
      case onAppear
      case onDisappear
      case disclosureTapped(Session)
      case yearSelected(ConferenceYear)
      case daySelected(Days)
      case favoriteTapped(Session)
    }

    public enum Delegate: Equatable {
      case showVideoDetail(Session, VideoMetadata, ConferenceYear)
      case showScheduleDetail(
        Session, proposalId: String?, isFavorite: Bool, favoriteCount: Int,
        relatedSessions: [RelatedSession])
    }
  }

  @Reducer
  public enum Path {
    case detail(ScheduleDetail)
  }

  @Reducer
  public enum Destination {
    case detail(ScheduleDetail)
  }

  private enum CancelID { case timer }

  @Dependency(DataClient.self) var dataClient
  @Dependency(\.scheduleAPIClient) var apiClient
  @Dependency(\.continuousClock) var clock
  @Dependency(\.date) var date

  public init() {}

  public var body: some ReducerOf<Self> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case .view(.onAppear):
        state.currentTime = date.now
        let year = state.selectedYear
        let shouldLoadAllSessions = state.allSessions.isEmpty
        let shouldLoadFavorites = !state.hasLoadedFavorites
        let dataClient = dataClient
        let apiClient = apiClient
        return .merge(
          .send(
            .fetchResponse(
              Result {
                let day1 = try dataClient.fetchDay1(year)
                let day2 = try dataClient.fetchDay2(year)
                let day3 = try? dataClient.fetchDay3(year)
                let videos = (try? dataClient.fetchVideos(year)) ?? []
                return .init(day1: day1, day2: day2, day3: day3, videos: videos)
              })),
          shouldLoadAllSessions
            ? .run { send in
              var results: [SearchableSession] = []
              for year in ConferenceYear.allCases {
                var conferences: [Conference] = []
                for fetch in [dataClient.fetchDay1, dataClient.fetchDay2, dataClient.fetchDay3] {
                  do {
                    conferences.append(try fetch(year))
                  } catch is DataClientError {
                    // Resource not found for this year/day — expected
                  } catch let error as DecodingError {
                    assertionFailure(error.localizedDescription)
                  } catch {
                    logger.error("Failed to fetch conference data: \(error)")
                  }
                }
                for conference in conferences {
                  for schedule in conference.schedules {
                    for session in schedule.sessions {
                      guard session.description != nil else { continue }
                      let corpus = Schedule.buildSearchCorpus(session: session)
                      results.append(
                        SearchableSession(year: year, session: session, searchCorpus: corpus))
                    }
                  }
                }
              }
              await send(.allSessionsLoaded(results))
            }
            : .none,
          shouldLoadFavorites
            ? .run { send in
              do {
                let ids = try await apiClient.fetchFavorites(DeviceIdentifier.current)
                await send(.favoritesLoaded(Set(ids)))
              } catch {
                await send(.favoritesLoaded([]))
              }
            }
            : .none,
          .run { send in
            if let counts = try? await apiClient.fetchFavoriteCounts() {
              await send(.favoriteCountsLoaded(counts))
            }
          },
          .run { [clock] send in
            for await _ in clock.timer(interval: .seconds(30)) {
              await send(.timerTicked)
            }
          }
          .cancellable(id: CancelID.timer, cancelInFlight: true)
        )
      case .view(.onDisappear):
        return .cancel(id: CancelID.timer)
      case .view(.yearSelected(let year)):
        state.selectedYear = year
        state.selectedDay = .day1
        state.day1 = nil
        state.day2 = nil
        state.day3 = nil
        state.videoMetadata = [:]
        return .send(.view(.onAppear))
      case .view(.daySelected(let day)):
        state.selectedDay = day
        return .none
      case .view(.favoriteTapped(let session)):
        guard let proposalId = session.proposalId else { return .none }
        // Optimistic toggle
        let wasFavorite = state.favoriteProposalIds.contains(proposalId)
        let previousCount = state.favoriteCounts[proposalId] ?? 0
        if wasFavorite {
          state.favoriteProposalIds.remove(proposalId)
        } else {
          state.favoriteProposalIds.insert(proposalId)
        }
        let apiClient = apiClient
        return .run { send in
          let result = try await apiClient.toggleFavorite(proposalId, DeviceIdentifier.current)
          await send(.favoriteToggled(proposalId, result.isFavorite, result.count))
        } catch: { _, send in
          await send(.favoriteToggled(proposalId, wasFavorite, previousCount))
        }
      case .view(.disclosureTapped(let session)):
        guard session.description != nil, session.speakers != nil else {
          return .none
        }
        if let videoId = session.youtubeVideoId {
          let videoMeta =
            state.videoMetadata[videoId]
            ?? VideoMetadata(sessionTitle: session.title, youtubeVideoId: videoId)
          return .send(.delegate(.showVideoDetail(session, videoMeta, state.selectedYear)))
        } else {
          let isFavorite =
            session.proposalId.map { state.favoriteProposalIds.contains($0) } ?? false
          let favoriteCount =
            session.proposalId.flatMap { state.favoriteCounts[$0] } ?? 0
          let relatedSessions = Schedule.findRelatedSessions(
            for: session, from: state.allSessions)
          #if os(macOS)
            return .send(
              .delegate(
                .showScheduleDetail(
                  session, proposalId: session.proposalId, isFavorite: isFavorite,
                  favoriteCount: favoriteCount, relatedSessions: relatedSessions)))
          #else
            let detailState = ScheduleDetail.State(
              proposalId: session.proposalId,
              isFavorite: isFavorite,
              favoriteCount: favoriteCount,
              title: session.title,
              description: session.description!,
              requirements: session.requirements,
              speakers: session.speakers!,
              relatedSessions: relatedSessions
            )
            state.path.append(.detail(detailState))
            return .none
          #endif
        }
      case .fetchResponse(.success(let response)):
        state.day1 = response.day1
        state.day2 = response.day2
        state.day3 = response.day3
        state.videoMetadata = Dictionary(
          response.videos.map { ($0.youtubeVideoId, $0) },
          uniquingKeysWith: { first, _ in first }
        )
        return .none
      case .allSessionsLoaded(let sessions):
        state.allSessions = sessions
        return .none
      case .favoritesLoaded(let ids):
        state.favoriteProposalIds = ids
        state.hasLoadedFavorites = true
        return .none
      case .favoriteCountsLoaded(let counts):
        state.favoriteCounts = counts
        return .none
      case .favoriteToggled(let proposalId, let isFavorite, let count):
        if isFavorite {
          state.favoriteProposalIds.insert(proposalId)
        } else {
          state.favoriteProposalIds.remove(proposalId)
        }
        state.favoriteCounts[proposalId] = count
        return .none
      case .fetchResponse(.failure(let error as DecodingError)):
        assertionFailure(error.localizedDescription)
        return .none
      case .fetchResponse(.failure(let error)):
        logger.error("Failed to fetch schedules: \(error)")
        return .none
      case .path(.element(let id, action: .detail(.favoriteToggled(let isFavorite, let count)))):
        // Sync favorite state from detail back to schedule
        if case .detail(let detail) = state.path[id: id],
          let proposalId = detail.proposalId
        {
          if isFavorite {
            state.favoriteProposalIds.insert(proposalId)
          } else {
            state.favoriteProposalIds.remove(proposalId)
          }
          state.favoriteCounts[proposalId] = count
        }
        return .none
      case .path(
        .element(_, action: .detail(.delegate(.showRelatedSession(let session, let year))))
      ):
        guard session.description != nil, session.speakers != nil else { return .none }
        if let videoId = session.youtubeVideoId {
          let videoMeta =
            state.videoMetadata[videoId]
            ?? VideoMetadata(sessionTitle: session.title, youtubeVideoId: videoId)
          return .send(.delegate(.showVideoDetail(session, videoMeta, year)))
        }
        let isFavorite =
          session.proposalId.map { state.favoriteProposalIds.contains($0) } ?? false
        let favoriteCount =
          session.proposalId.flatMap { state.favoriteCounts[$0] } ?? 0
        let relatedSessions = Schedule.findRelatedSessions(
          for: session, from: state.allSessions)
        let detailState = ScheduleDetail.State(
          proposalId: session.proposalId,
          isFavorite: isFavorite,
          favoriteCount: favoriteCount,
          title: session.title,
          description: session.description!,
          requirements: session.requirements,
          speakers: session.speakers!,
          relatedSessions: relatedSessions
        )
        state.path.append(.detail(detailState))
        return .none
      case .timerTicked:
        state.currentTime = date.now
        return .none
      case .binding, .path, .destination, .delegate:
        return .none
      }
    }
    .forEach(\.path, action: \.path)
    .ifLet(\.$destination, action: \.destination)
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

  public static func findRelatedSessions(
    for session: Session,
    from allSessions: [SearchableSession],
    limit: Int = 5
  ) -> [RelatedSession] {
    let currentTags = SessionTagging.generateTags(for: session)
    guard !currentTags.isEmpty else { return [] }

    let currentSpeakerNames = session.speakers?.map(\.name) ?? []

    struct ScoredResult {
      var related: RelatedSession
      var matchCount: Int
    }

    var scored: [ScoredResult] = []

    for searchable in allSessions {
      let candidate = searchable.session
      // Skip self
      if candidate.title == session.title,
        candidate.speakers?.first?.name == session.speakers?.first?.name
      {
        continue
      }

      let candidateTags = SessionTagging.generateTags(for: candidate)
      let matchCount = currentTags.intersection(candidateTags).count
      guard matchCount > 0 else { continue }

      let candidateSpeakerNames = candidate.speakers?.map(\.name) ?? []
      let isSameSpeaker =
        !currentSpeakerNames.isEmpty
        && currentSpeakerNames.contains {
          name in
          candidateSpeakerNames.contains { SessionTagging.speakerNamesMatch(name, $0) }
        }

      scored.append(
        ScoredResult(
          related: RelatedSession(
            year: searchable.year,
            session: candidate,
            speakerImageName: candidate.speakers?.first?.imageName,
            speakerName: candidate.speakers?.first?.name,
            isSameSpeaker: isSameSpeaker
          ),
          matchCount: matchCount
        )
      )
    }

    scored.sort { lhs, rhs in
      if lhs.related.isSameSpeaker != rhs.related.isSameSpeaker {
        return lhs.related.isSameSpeaker
      }
      return lhs.matchCount > rhs.matchCount
    }

    return scored.prefix(limit).map(\.related)
  }
}

extension Schedule.State {
  var searchResults: [Schedule.SearchableSession] {
    let query = searchText.lowercased().trimmingCharacters(in: .whitespaces)
    guard !query.isEmpty else { return [] }
    return allSessions.filter { $0.searchCorpus.contains(query) }
  }

  var isShowingSearchResults: Bool {
    isSearchBarPresented && !searchText.trimmingCharacters(in: .whitespaces).isEmpty
  }
}

extension Schedule.Path.State: Equatable {}
extension Schedule.Destination.State: Equatable {}

/// The resource bundle for ScheduleFeature (contains speaker images).
public let scheduleFeatureBundle: Bundle = .module

@ViewAction(for: Schedule.self)
public struct ScheduleView: View {

  @Bindable public var store: StoreOf<Schedule>

  public init(store: StoreOf<Schedule>) {
    self.store = store
  }

  public var body: some View {
    #if os(macOS)
      root
    #else
      NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
        root
      } destination: { store in
        switch store.state {
        case .detail:
          if let store = store.scope(state: \.detail, action: \.detail) {
            ScheduleDetailView(store: store)
          }
        }
      }
    #endif
  }

  @ViewBuilder
  var root: some View {
    Group {
      if store.isShowingSearchResults {
        searchResultsList
      } else {
        normalScheduleContent
      }
    }
    .onAppear(perform: {
      send(.onAppear)
    })
    .onDisappear(perform: {
      send(.onDisappear)
    })
    .navigationTitle(Text("Schedule", bundle: .module))
    .searchable(text: $store.searchText, isPresented: $store.isSearchBarPresented)
    .toolbar {
      #if os(macOS)
        ToolbarItem(placement: .primaryAction) {
          timeTravelMenu()
        }
      #else
        ToolbarItem(placement: .topBarTrailing) {
          timeTravelMenu()
        }
      #endif
    }
  }

  @ViewBuilder
  var normalScheduleContent: some View {
    ScrollView {
      Picker("Days", selection: $store.selectedDay) {
        Text(Schedule.Days.day1.rawValue, bundle: .module)
          .tag(Schedule.Days.day1)
        Text(Schedule.Days.day2.rawValue, bundle: .module)
          .tag(Schedule.Days.day2)
        if store.day3 != nil {
          Text(Schedule.Days.day3.rawValue, bundle: .module)
            .tag(Schedule.Days.day3)
        }
      }
      .pickerStyle(.segmented)
      .padding(.horizontal)
      switch store.selectedDay {
      case .day1:
        if let day1 = store.day1 {
          conferenceList(conference: day1)
        } else {
          Text("")
        }
      case .day2:
        if let day2 = store.day2 {
          conferenceList(conference: day2)
        } else {
          Text("")
        }
      case .day3:
        if let day3 = store.day3 {
          conferenceList(conference: day3)
        } else {
          Text("")
        }
      }
    }
  }

  @ViewBuilder
  var searchResultsList: some View {
    let results = store.searchResults
    if results.isEmpty {
      ContentUnavailableView.search(text: store.searchText)
    } else {
      ScrollView {
        LazyVStack(alignment: .leading, spacing: 12) {
          ForEach(results, id: \.self) { result in
            Button {
              send(.disclosureTapped(result.session))
            } label: {
              searchResultRow(result: result)
                .padding()
            }
            .glassIfAvailable()
          }
        }
        .padding()
        .glassEffectContainerIfAvailable()
      }
    }
  }

  @ViewBuilder
  func searchResultRow(result: Schedule.SearchableSession) -> some View {
    HStack(spacing: 8) {
      if let speakers = result.session.speakers {
        ForEach(speakers.prefix(2), id: \.self) { speaker in
          Image(speaker.imageName, bundle: .module)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .clipShape(Circle())
            .frame(width: 44)
            .accessibilityElement(children: .ignore)
            .accessibilityIgnoresInvertColors()
        }
      } else {
        Image(.tokyo)
          .resizable()
          .aspectRatio(contentMode: .fit)
          .clipShape(Circle())
          .frame(width: 44)
          .accessibilityElement(children: .ignore)
          .accessibilityIgnoresInvertColors()
      }
      VStack(alignment: .leading, spacing: 2) {
        Text(LocalizedStringKey(result.session.title), bundle: .module)
          .font(.body)
          .multilineTextAlignment(.leading)
        if let speakers = result.session.speakers {
          Text(ListFormatter.localizedString(byJoining: speakers.map(\.name)))
            .font(.caption)
            .foregroundStyle(labelColor)
        }
        Text(String(result.year.rawValue))
          .font(.caption2)
          .foregroundStyle(secondaryLabelColor)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .accessibilityElement(children: .combine)
    }
  }

  @ViewBuilder
  func timeTravelMenu() -> some View {
    Menu {
      ForEach(ConferenceYear.allCases, id: \.self) { year in
        Button {
          send(.yearSelected(year))
        } label: {
          if year == store.selectedYear {
            Label(String(year.rawValue), systemImage: "checkmark")
          } else {
            Text(String(year.rawValue))
          }
        }
      }
    } label: {
      Label(String(store.selectedYear.rawValue), systemImage: "calendar")
    }
  }

  @ViewBuilder
  func conferenceList(conference: Conference) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(conference.date, style: .date)
        .font(.title2)
        .accessibilityAddTraits(.isHeader)
      ForEach(conference.schedules.indices, id: \.self) { index in
        let schedule = conference.schedules[index]
        VStack(alignment: .leading, spacing: 4) {
          HStack(spacing: 6) {
            Text(
              schedule.time.formatted(date: .omitted, time: .shortened)
                + (schedule.endTime.map { " - " + $0.formatted(date: .omitted, time: .shortened) }
                  ?? "")
            )
            .font(.subheadline.bold())
            .accessibilityAddTraits(.isHeader)
            if store.liveScheduleIndex == index {
              liveBadge
            }
          }
          ForEach(schedule.sessions, id: \.self) { session in
            if session.description != nil {
              Button {
                send(.disclosureTapped(session))
              } label: {
                listRow(session: session, hasVideo: session.youtubeVideoId != nil)
                  .padding()
              }
              .glassIfAvailable()
              .overlay(alignment: .topTrailing) {
                favoriteButton(session: session)
              }
            } else {
              listRow(session: session, hasVideo: false)
                .padding()
                .glassIfAvailable()
            }
          }
        }
      }
    }
    .padding()
    .glassEffectContainerIfAvailable()
  }

  @ViewBuilder
  func listRow(session: Session, hasVideo: Bool) -> some View {
    HStack(spacing: 8) {
      VStack {
        if let speakers = session.speakers {
          if speakers.count > 1 {
            let iconSize: CGFloat =
              switch speakers.count {
              case 2: 44
              case 3...4: 34
              default: 28
              }
            let spacing = -(iconSize * 0.1).rounded()
            ZStack(alignment: .bottomTrailing) {
              Grid(alignment: .center, horizontalSpacing: spacing, verticalSpacing: spacing) {
                ForEach(Array(stride(from: 0, to: speakers.count, by: 2)), id: \.self) { i in
                  GridRow {
                    let end = min(i + 2, speakers.count)
                    let isLastSingle = (end - i == 1)
                    ForEach(speakers[i..<end], id: \.self) { speaker in
                      Image(speaker.imageName, bundle: .module)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(.background, lineWidth: 2))
                        .frame(width: iconSize)
                        .accessibilityElement(children: .ignore)
                        .accessibilityIgnoresInvertColors()
                        .gridCellColumns(isLastSingle ? 2 : 1)
                    }
                  }
                }
              }
              if hasVideo {
                Image(systemName: "play.circle.fill")
                  .font(.body)
                  .foregroundStyle(.white, Color.accentColor)
              }
            }
          } else if let speaker = speakers.first {
            ZStack(alignment: .bottomTrailing) {
              Image(speaker.imageName, bundle: .module)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .clipShape(Circle())
                .frame(width: 60)
                .accessibilityElement(children: .ignore)
                .accessibilityIgnoresInvertColors()
              if hasVideo {
                Image(systemName: "play.circle.fill")
                  .font(.body)
                  .foregroundStyle(.white, Color.accentColor)
              }
            }
          }
        } else {
          Image(.tokyo)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .clipShape(Circle())
            .frame(width: 60)
            .accessibilityElement(children: .ignore)
            .accessibilityIgnoresInvertColors()
        }
      }
      VStack(alignment: .leading) {
        if session.title == "Office hour", let speakers = session.speakers {
          let title = officeHourTitle(speakers: speakers)
          Text(title)
            .font(.title3)
            .multilineTextAlignment(.leading)
        } else {
          Text(LocalizedStringKey(session.title), bundle: .module)
            .font(.title3)
            .multilineTextAlignment(.leading)
        }
        if let speakers = session.speakers {
          Text(ListFormatter.localizedString(byJoining: speakers.map(\.name)))
            .foregroundStyle(labelColor)
            .multilineTextAlignment(.leading)
        }
        if let summary = session.summary {
          if session.title == "Office hour", let speakers = session.speakers {
            let description = officeHourDescription(speakers: speakers)
            Text(description)
              .lineLimit(2)
              .foregroundStyle(secondaryLabelColor)
          } else {
            Text(LocalizedStringKey(summary), bundle: .module)
              .lineLimit(2)
              .foregroundStyle(secondaryLabelColor)
          }
        }
        if let sponsor = session.sponsor {
          Text(String(localized: "Sponsored by \(sponsor)", bundle: .module))
            .font(.caption)
            .foregroundStyle(secondaryLabelColor)
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .accessibilityElement(children: .combine)
    }
  }

  @ViewBuilder
  func favoriteButton(session: Session) -> some View {
    if let proposalId = session.proposalId {
      let isFavorite = store.favoriteProposalIds.contains(proposalId)
      let count = store.favoriteCounts[proposalId] ?? 0
      Button {
        send(.favoriteTapped(session))
      } label: {
        HStack(spacing: 2) {
          Image(systemName: isFavorite ? "heart.fill" : "heart")
            .foregroundStyle(isFavorite ? Color.red : Color.secondary)
          if count > 0 {
            Text("\(count)")
              .font(.caption2)
              .foregroundStyle(isFavorite ? Color.red : Color.secondary)
          }
        }
        .padding(12)
      }
      .buttonStyle(.plain)
      .accessibilityLabel(isFavorite ? "Remove from favorites" : "Add to favorites")
      .accessibilityValue(count > 0 ? "\(count)" : "")
    }
  }

  func officeHourTitle(speakers: [Speaker]) -> String {
    let names = givenNameList(speakers: speakers)
    return String(localized: "Office hour \(names)", bundle: .module)
  }

  func officeHourDescription(speakers: [Speaker]) -> String {
    let names = givenNameList(speakers: speakers)
    return String(localized: "Office hour description \(names)", bundle: .module)
  }

  private func givenNameList(speakers: [Speaker]) -> String {
    let givenNames = speakers.compactMap {
      let name = $0.name
      let components = try! PersonNameComponents(name).givenName
      return components
    }
    let formatter = ListFormatter()
    return formatter.string(from: givenNames)!
  }

  private var liveBadge: some View {
    Text("LIVE", bundle: .module)
      .font(.caption2.bold())
      .foregroundStyle(.white)
      .padding(.horizontal, 6)
      .padding(.vertical, 2)
      .background(.red, in: Capsule())
  }

  private var labelColor: Color {
    #if os(macOS)
      Color(nsColor: .labelColor)
    #else
      Color(uiColor: .label)
    #endif
  }

  private var secondaryLabelColor: Color {
    #if os(macOS)
      Color(nsColor: .secondaryLabelColor)
    #else
      Color(uiColor: .secondaryLabel)
    #endif
  }
}

#Preview {
  ScheduleView(
    store: .init(
      initialState: .init(),
      reducer: {
        Schedule()
      }))
}
