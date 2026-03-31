import ComposableArchitecture
import Foundation
import GuidanceFeature
import LiveTranslationFeature
import ScheduleFeature
import SharedModels
import SponsorFeature
import SwiftUI
import TipKit
import VideoFeature
import trySwiftFeature

// MARK: - AppReducer

@Reducer
public struct AppReducer {

  public enum SidebarItem: Hashable, Sendable {
    case day1, day2, day3
    case liveTranslation
    case venue
    case sponsors
    case organizers
    case acknowledgements
    case pastYear(ConferenceYear)
  }

  public enum ExternalLink: Equatable, Sendable {
    case codeOfConduct, privacyPolicy, luma, website
  }

  @Reducer
  public enum DetailColumn {
    case scheduleDetail(ScheduleDetail)
    case videoDetail(VideoDetail)
    case profileDetail(Profile)
  }

  @ObservableState
  public struct State: Equatable {
    var schedule = ScheduleFeature.Schedule.State()
    var liveTranslation = LiveTranslation.State()
    var guidance = Guidance.State()
    var sponsors = SponsorsList.State()
    var trySwift = TrySwift.State()

    // Sidebar
    var selectedSidebarItem: SidebarItem? = .day1

    // Sidebar detail: standalone Organizers with profile navigation
    var sidebarOrganizers = Organizers.State()
    @Presents var sidebarProfile: Profile.State?

    // Sidebar detail: standalone Acknowledgements
    var sidebarAcknowledgements = Acknowledgements.State()

    // macOS: 3rd column detail
    @Presents var detailColumn: DetailColumn.State?

    // iOS: Video detail (presented as sheet from schedule)
    @Presents var videoDetail: VideoDetail.State?

    public init() {
      try? Tips.configure([.displayFrequency(.immediate)])
    }
  }

  public enum Action {
    case schedule(ScheduleFeature.Schedule.Action)
    case liveTranslation(LiveTranslation.Action)
    case guidance(Guidance.Action)
    case sponsors(SponsorsList.Action)
    case trySwift(TrySwift.Action)

    // Sidebar
    case sidebarItemSelected(SidebarItem?)
    case openExternalLink(ExternalLink)

    // Sidebar detail
    case sidebarOrganizers(Organizers.Action)
    case sidebarProfile(PresentationAction<Profile.Action>)
    case sidebarAcknowledgements(Acknowledgements.Action)

    // Detail column (macOS 3rd column)
    case detailColumn(PresentationAction<DetailColumn.Action>)

    // Video detail (iOS sheet)
    case videoDetail(PresentationAction<VideoDetail.Action>)
  }

  public init() {}

  public var body: some ReducerOf<Self> {
    Scope(state: \.schedule, action: \.schedule) {
      ScheduleFeature.Schedule()
    }
    Scope(state: \.liveTranslation, action: \.liveTranslation) {
      LiveTranslation()
    }
    Scope(state: \.guidance, action: \.guidance) {
      Guidance()
    }
    Scope(state: \.sponsors, action: \.sponsors) {
      SponsorsList()
    }
    Scope(state: \.trySwift, action: \.trySwift) {
      TrySwift()
    }
    Scope(state: \.sidebarOrganizers, action: \.sidebarOrganizers) {
      Organizers()
    }
    Scope(state: \.sidebarAcknowledgements, action: \.sidebarAcknowledgements) {
      Acknowledgements()
    }

    Reduce { state, action in
      switch action {
      case .sidebarItemSelected(let item):
        let previousYear: ConferenceYear
        switch state.selectedSidebarItem {
        case .pastYear(let year):
          previousYear = year
        default:
          previousYear = .latest
        }
        state.selectedSidebarItem = item
        state.detailColumn = nil
        let targetDay: ScheduleFeature.Schedule.Days
        let targetYear: ConferenceYear
        switch item {
        case .day1:
          targetDay = .day1
          targetYear = .latest
        case .day2:
          targetDay = .day2
          targetYear = .latest
        case .day3:
          targetDay = .day3
          targetYear = .latest
        case .pastYear(let year):
          targetDay = .day1
          targetYear = year
        default: return .none
        }
        if targetYear != previousYear {
          return .merge(
            .send(.schedule(.view(.yearSelected(targetYear)))),
            .send(.schedule(.view(.daySelected(targetDay))))
          )
        } else {
          return .send(.schedule(.view(.daySelected(targetDay))))
        }

      case .openExternalLink(let link):
        switch link {
        case .codeOfConduct:
          return .send(.trySwift(.view(.codeOfConductTapped)))
        case .privacyPolicy:
          return .send(.trySwift(.view(.privacyPolicyTapped)))
        case .luma:
          return .send(.trySwift(.view(.ticketTapped)))
        case .website:
          return .send(.trySwift(.view(.websiteTapped)))
        }

      case .sidebarOrganizers(.delegate(.organizerTapped(let organizer))):
        #if os(macOS)
          state.detailColumn = .profileDetail(.init(organizer: organizer))
        #else
          state.sidebarProfile = .init(organizer: organizer)
        #endif
        return .none

      case .schedule(.view(.yearSelected(let year))):
        if year == .latest {
          if case .pastYear = state.selectedSidebarItem {
            state.selectedSidebarItem = .day1
          }
        } else {
          state.selectedSidebarItem = .pastYear(year)
        }
        state.detailColumn = nil
        return .none

      case .schedule(.delegate(.showVideoDetail(let session, let videoMeta, let year))):
        #if os(macOS)
          state.detailColumn = .videoDetail(
            .init(session: session, videoMetadata: videoMeta, conferenceYear: year))
        #else
          state.videoDetail = .init(
            session: session, videoMetadata: videoMeta, conferenceYear: year)
        #endif
        return .none

      case .schedule(
        .delegate(
          .showScheduleDetail(
            let session, proposalId: let proposalId, isFavorite: let isFavorite,
            favoriteCount: let favoriteCount))
      ):
        guard let description = session.description, let speakers = session.speakers else {
          return .none
        }
        state.detailColumn = .scheduleDetail(
          .init(
            proposalId: proposalId,
            isFavorite: isFavorite,
            favoriteCount: favoriteCount,
            title: session.title,
            description: description,
            requirements: session.requirements,
            speakers: speakers
          ))
        return .none

      case .schedule, .liveTranslation, .guidance, .sponsors, .trySwift,
        .sidebarOrganizers, .sidebarProfile, .sidebarAcknowledgements,
        .detailColumn, .videoDetail:
        return .none
      }
    }
    .ifLet(\.$sidebarProfile, action: \.sidebarProfile) {
      Profile()
    }
    .ifLet(\.$detailColumn, action: \.detailColumn)
    .ifLet(\.$videoDetail, action: \.videoDetail) {
      VideoDetail()
    }
  }
}

extension AppReducer.DetailColumn.State: Equatable {}

// MARK: - AppView

public struct AppView: View {
  @Bindable var store: StoreOf<AppReducer>
  @State private var isPastYearsExpanded = false

  #if !os(macOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
  #endif

  public init(store: StoreOf<AppReducer>) {
    self.store = store
  }

  public var body: some View {
    Group {
      #if os(macOS)
        macOSSidebarLayout
      #else
        if horizontalSizeClass == .regular {
          sidebarLayout
        } else {
          tabLayout
        }
      #endif
    }
    #if !os(macOS)
      .sheet(
        item: $store.scope(state: \.videoDetail, action: \.videoDetail)
      ) { videoDetailStore in
        NavigationStack {
          VideoDetailView(store: videoDetailStore, speakerImageBundle: scheduleFeatureBundle)
          .toolbar {
            Button(role: .close) {
              store.send(.videoDetail(.dismiss))
            }
          }
        }
      }
    #endif
  }

  // MARK: iPhone TabView

  @ViewBuilder
  var tabLayout: some View {
    TabView {
      ScheduleView(store: store.scope(state: \.schedule, action: \.schedule))
        .tabItem {
          Label(String(localized: "Schedule", bundle: .module), systemImage: "calendar")
        }
      LiveTranslationView(
        store: store.scope(state: \.liveTranslation, action: \.liveTranslation)
      )
      .tabItem {
        Label(String(localized: "Translation", bundle: .module), systemImage: "text.bubble")
      }
      GuidanceView(store: store.scope(state: \.guidance, action: \.guidance))
        .tabItem {
          Label(String(localized: "Venue", bundle: .module), systemImage: "map")
        }
      SponsorsListView(store: store.scope(state: \.sponsors, action: \.sponsors))
        .tabItem {
          Label(String(localized: "Sponsors", bundle: .module), systemImage: "building.2")
        }
      TrySwiftView(store: store.scope(state: \.trySwift, action: \.trySwift))
        .tabItem {
          Image(.rikoTokyo)
          Text("About", bundle: .module)
        }
    }
    #if os(iOS)
      .tabBarMinimizeBehavior(.onScrollDown)
    #endif
  }

  // MARK: macOS Sidebar Layout (3 columns)

  #if os(macOS)
    @ViewBuilder
    var macOSSidebarLayout: some View {
      NavigationSplitView {
        sidebarContent
      } content: {
        detailContent
      } detail: {
        macOSDetailColumnView
      }
    }

    @ViewBuilder
    var macOSDetailColumnView: some View {
      if let scheduleStore = store.scope(
        state: \.detailColumn?.scheduleDetail, action: \.detailColumn.scheduleDetail)
      {
        ScheduleDetailView(store: scheduleStore)
      } else if let videoStore = store.scope(
        state: \.detailColumn?.videoDetail, action: \.detailColumn.videoDetail)
      {
        VideoDetailView(store: videoStore, speakerImageBundle: scheduleFeatureBundle)
      } else if let profileStore = store.scope(
        state: \.detailColumn?.profileDetail, action: \.detailColumn.profileDetail)
      {
        ProfileView(store: profileStore)
      } else {
        ContentUnavailableView {
          Label(
            String(localized: "Select a Session", bundle: .module), systemImage: "text.document")
        } description: {
          Text("Choose a session from the schedule to view details", bundle: .module)
        }
      }
    }
  #endif

  // MARK: iPad Sidebar Layout (2 columns)

  @ViewBuilder
  var sidebarLayout: some View {
    NavigationSplitView {
      sidebarContent
    } detail: {
      detailContent
    }
  }

  @ViewBuilder
  var sidebarContent: some View {
    List(
      selection: Binding(
        get: { store.selectedSidebarItem },
        set: { store.send(.sidebarItemSelected($0)) }
      )
    ) {
      Section {
        Label(String(localized: "Day 1", bundle: .module), systemImage: "1.calendar")
          .tag(AppReducer.SidebarItem.day1)
        Label(String(localized: "Day 2", bundle: .module), systemImage: "2.calendar")
          .tag(AppReducer.SidebarItem.day2)
        Label(String(localized: "Day 3", bundle: .module), systemImage: "3.calendar")
          .tag(AppReducer.SidebarItem.day3)
        Label(String(localized: "Live Translation", bundle: .module), systemImage: "text.bubble")
          .tag(AppReducer.SidebarItem.liveTranslation)
        Label(String(localized: "Venue", bundle: .module), systemImage: "map")
          .tag(AppReducer.SidebarItem.venue)
        Label(String(localized: "Sponsors", bundle: .module), systemImage: "building.2")
          .tag(AppReducer.SidebarItem.sponsors)
        Label(String(localized: "Organizers", bundle: .module), systemImage: "person.3")
          .tag(AppReducer.SidebarItem.organizers)
      } header: {
        Text("try! Swift Tokyo \(String(ConferenceYear.latest.rawValue))")
      }

      Section {
        Label(String(localized: "Acknowledgements", bundle: .module), systemImage: "heart")
          .tag(AppReducer.SidebarItem.acknowledgements)

        Button {
          store.send(.openExternalLink(.codeOfConduct))
        } label: {
          externalLinkLabel(
            String(localized: "Code of Conduct", bundle: .module), systemImage: "doc.text")
        }
        #if os(macOS)
          .buttonStyle(.link)
        #else
          .buttonStyle(.plain)
        #endif
        Button {
          store.send(.openExternalLink(.privacyPolicy))
        } label: {
          externalLinkLabel(
            String(localized: "Privacy Policy", bundle: .module), systemImage: "hand.raised")
        }
        #if os(macOS)
          .buttonStyle(.link)
        #else
          .buttonStyle(.plain)
        #endif

        Button {
          store.send(.openExternalLink(.luma))
        } label: {
          externalLinkLabel(String(localized: "Luma", bundle: .module), systemImage: "ticket")
        }
        #if os(macOS)
          .buttonStyle(.link)
        #else
          .buttonStyle(.plain)
        #endif

        Button {
          store.send(.openExternalLink(.website))
        } label: {
          externalLinkLabel(
            String(localized: "try! Swift Website", bundle: .module), systemImage: "safari")
        }
        #if os(macOS)
          .buttonStyle(.link)
        #else
          .buttonStyle(.plain)
        #endif

      }

      Section(isExpanded: $isPastYearsExpanded) {
        ForEach(pastYears, id: \.self) { year in
          Label("Tokyo \(String(year.rawValue))", systemImage: "calendar")
            .tag(AppReducer.SidebarItem.pastYear(year))
        }
      } header: {
        Text("Past try! Swift")
      }
    }
    .listStyle(.sidebar)
    .navigationTitle("try! Swift")
  }

  @ViewBuilder
  var detailContent: some View {
    if let item = store.selectedSidebarItem {
      switch item {
      case .day1, .day2, .day3, .pastYear:
        ScheduleView(store: store.scope(state: \.schedule, action: \.schedule))
      case .liveTranslation:
        LiveTranslationView(
          store: store.scope(state: \.liveTranslation, action: \.liveTranslation))
      case .venue:
        GuidanceView(store: store.scope(state: \.guidance, action: \.guidance))
      case .sponsors:
        SponsorsListView(store: store.scope(state: \.sponsors, action: \.sponsors))
      case .organizers:
        NavigationStack {
          OrganizersView(
            store: store.scope(state: \.sidebarOrganizers, action: \.sidebarOrganizers)
          )
          .navigationDestination(
            item: $store.scope(state: \.sidebarProfile, action: \.sidebarProfile)
          ) { profileStore in
            ProfileView(store: profileStore)
          }
        }
      case .acknowledgements:
        NavigationStack {
          AcknowledgementsView(
            store: store.scope(
              state: \.sidebarAcknowledgements, action: \.sidebarAcknowledgements))
        }
      }
    } else {
      ContentUnavailableView {
        Label("try! Swift Tokyo", systemImage: "swift")
      } description: {
        Text("Select an item from the sidebar")
      }
    }
  }

  @ViewBuilder
  private func externalLinkLabel(_ title: String, systemImage: String) -> some View {
    Label {
      HStack {
        Text(title)
        Spacer()
        Image(systemName: "arrow.up.forward")
          .foregroundStyle(.tertiary)
          .font(.caption)
          .accessibilityHidden(true)
      }
    } icon: {
      Image(systemName: systemImage)
    }
  }

  private var pastYears: [ConferenceYear] {
    ConferenceYear.allCases
      .filter { $0 != .latest }
      .sorted { $0.rawValue > $1.rawValue }
  }
}

#Preview {
  AppView(
    store: .init(
      initialState: .init(),
      reducer: {
        AppReducer()
      }))
}
