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
    var allSessions: [SearchableSession] = []
    var day1: Conference?
    var day2: Conference?
    var day3: Conference?
    var videoMetadata: [String: VideoMetadata] = [:]
    @Presents var destination: Destination.State?

    public init() {}
  }

  public enum Action: BindableAction, ViewAction {
    case binding(BindingAction<State>)
    case path(StackAction<Path.State, Path.Action>)
    case destination(PresentationAction<Destination.Action>)
    case view(View)
    case fetchResponse(Result<SchedulesResponse, Error>)
    case allSessionsLoaded([SearchableSession])
    case delegate(Delegate)

    @CasePathable
    public enum View {
      case onAppear
      case disclosureTapped(Session)
      case yearSelected(ConferenceYear)
      case daySelected(Days)
    }

    public enum Delegate: Equatable {
      case showVideoDetail(Session, VideoMetadata, ConferenceYear)
    }
  }

  @Reducer
  public enum Path {
    case detail(ScheduleDetail)
  }

  @Reducer
  public enum Destination {}

  @Dependency(DataClient.self) var dataClient

  public init() {}

  public var body: some ReducerOf<Self> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case .view(.onAppear):
        let year = state.selectedYear
        let shouldLoadAllSessions = state.allSessions.isEmpty
        let dataClient = dataClient
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
            : .none
        )
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
      case .view(.disclosureTapped(let session)):
        guard let description = session.description, let speakers = session.speakers else {
          return .none
        }
        if let videoMeta = state.videoMetadata[session.title] {
          return .send(.delegate(.showVideoDetail(session, videoMeta, state.selectedYear)))
        } else {
          state.path.append(
            .detail(
              .init(
                title: session.title,
                description: description,
                requirements: session.requirements,
                speakers: speakers
              )
            )
          )
        }
        return .none
      case .fetchResponse(.success(let response)):
        state.day1 = response.day1
        state.day2 = response.day2
        state.day3 = response.day3
        state.videoMetadata = Dictionary(
          response.videos.map { ($0.sessionTitle, $0) },
          uniquingKeysWith: { first, _ in first }
        )
        return .none
      case .allSessionsLoaded(let sessions):
        state.allSessions = sessions
        return .none
      case .fetchResponse(.failure(let error as DecodingError)):
        assertionFailure(error.localizedDescription)
        return .none
      case .fetchResponse(.failure(let error)):
        logger.error("Failed to fetch schedules: \(error)")
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
            #if os(macOS)
              .buttonStyle(.plain)
            #else
              .glassEffectIfAvailable(.regular.interactive(), in: .rect(cornerRadius: 16))
            #endif
          }
        }
        .padding()
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
      ForEach(conference.schedules, id: \.self) { schedule in
        VStack(alignment: .leading, spacing: 4) {
          Text(
            schedule.time.formatted(date: .omitted, time: .shortened)
              + (schedule.endTime.map { " - " + $0.formatted(date: .omitted, time: .shortened) }
                ?? "")
          )
          .font(.subheadline.bold())
          .accessibilityAddTraits(.isHeader)
          ForEach(schedule.sessions, id: \.self) { session in
            if session.description != nil {
              Button {
                send(.disclosureTapped(session))
              } label: {
                listRow(session: session, hasVideo: store.videoMetadata[session.title] != nil)
                  .padding()
              }
              #if os(macOS)
                .buttonStyle(.plain)
              #else
                .glassEffectIfAvailable(.regular.interactive(), in: .rect(cornerRadius: 16))
              #endif
            } else {
              listRow(session: session, hasVideo: false)
                .padding()
                #if !os(macOS)
                  .glassEffectIfAvailable(.regular, in: .rect(cornerRadius: 16))
                #endif
            }
          }
        }
      }
    }
    .padding()
  }

  @ViewBuilder
  func listRow(session: Session, hasVideo: Bool) -> some View {
    HStack(spacing: 8) {
      VStack {
        if let speakers = session.speakers {
          ForEach(speakers, id: \.self) { speaker in
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
                  .font(.caption)
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
              .foregroundStyle(secondaryLabelColor)
          } else {
            Text(LocalizedStringKey(summary), bundle: .module)
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
