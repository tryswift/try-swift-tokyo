import SharedModels
import SwiftUI

/// Schedule screen for Android.
/// Uses the same SwiftUI syntax as iOS - the only difference is state management
/// (iOS uses TCA, Android uses @Observable ViewModel).
public struct ScheduleScreen: View {
  @State private var viewModel = ScheduleViewModel()

  private let screenBackground = Color(red: 0.95, green: 0.96, blue: 0.98)
  private let cardBackground = Color.white
  private let accentColor = Color(red: 0.11, green: 0.35, blue: 0.85)

  public init() {}

  public var body: some View {
    NavigationStack {
      Group {
        if viewModel.isShowingSearchResults {
          searchResultsList
        } else {
          normalScheduleContent
        }
      }
      .navigationTitle("Schedule")
      #if SKIP
        .toolbar {
          ToolbarItem(placement: ToolbarItemPlacement.navigationBarLeading) {
            HStack {
              Image(systemName: "magnifyingglass")
              .foregroundStyle(Color.secondary)
              TextField("Search", text: $viewModel.searchText)
            }
          }
        }
        .onChange(of: viewModel.searchText) { _, newValue in
          viewModel.isSearchBarPresented = !newValue.trimmingCharacters(
            in: CharacterSet.whitespaces
          ).isEmpty
        }
      #else
        .searchable(text: $viewModel.searchText, isPresented: $viewModel.isSearchBarPresented)
      #endif
      .sheet(
        isPresented: Binding(
          get: { viewModel.selectedSession != nil },
          set: { if !$0 { viewModel.clearSelection() } }
        )
      ) {
        if let session = viewModel.selectedSession {
          NavigationStack {
            SessionDetailView(session: session, viewModel: viewModel)
              .navigationTitle("Session")
              #if os(iOS) || SKIP
                .navigationBarTitleDisplayMode(NavigationBarItem.TitleDisplayMode.inline)
                .toolbar {
                  ToolbarItem(placement: ToolbarItemPlacement.topBarTrailing) {
                    Button("Done") {
                      viewModel.clearSelection()
                    }
                  }
                }
              #endif
          }
        }
      }
      #if os(iOS) || SKIP
        .toolbar {
          ToolbarItem(placement: ToolbarItemPlacement.topBarTrailing) {
            timeTravelMenu()
          }
        }
      #endif
    }
    .background(screenBackground)
    .onAppear {
      viewModel.loadSchedules()
      viewModel.loadAllSessions()
      viewModel.loadFavorites()
    }
  }

  // MARK: - Time Travel Menu

  @ViewBuilder
  private func timeTravelMenu() -> some View {
    Menu {
      ForEach(ScheduleViewModel.availableYears, id: \.self) { year in
        Button {
          viewModel.selectYear(year)
        } label: {
          if year == viewModel.selectedYear {
            Label(String(year), systemImage: "checkmark")
          } else {
            Text(String(year))
          }
        }
      }
    } label: {
      Label(String(viewModel.selectedYear), systemImage: "calendar")
    }
  }

  // MARK: - Search Results

  @ViewBuilder
  private var searchResultsList: some View {
    let results = viewModel.searchResults
    if results.isEmpty {
      VStack {
        Spacer()
        Image(systemName: "magnifyingglass")
          .font(Font.system(size: 48))
          .foregroundStyle(Color.secondary)
        Text("No results for \"\(viewModel.searchText)\"")
          .foregroundStyle(Color.secondary)
        Spacer()
      }
    } else {
      ScrollView {
        LazyVStack(alignment: HorizontalAlignment.leading, spacing: 12) {
          ForEach(results, id: \.self) { result in
            Button {
              viewModel.selectSession(result.session)
            } label: {
              searchResultRow(result: result)
                .padding()
            }
            .buttonStyle(.plain)
          }
        }
        .padding()
      }
      .background(screenBackground)
    }
  }

  @ViewBuilder
  private func searchResultRow(result: SearchableSession) -> some View {
    HStack(spacing: 8) {
      if let speakers = result.session.speakers {
        VStack(spacing: 4) {
          ForEach(Array(speakers.prefix(2)), id: \.name) { speaker in
            SpeakerAvatarView(speaker: speaker, size: 44)
          }
        }
      }
      VStack(alignment: HorizontalAlignment.leading, spacing: 2) {
        Text(result.session.title)
          .font(Font.body)
          .multilineTextAlignment(TextAlignment.leading)
        if let speakers = result.session.speakers {
          Text(speakerNames(speakers))
            .font(Font.caption)
            .foregroundStyle(Color.secondary)
        }
        Text(String(result.year))
          .font(Font.caption2)
          .foregroundStyle(Color.secondary)
      }
      .frame(maxWidth: CGFloat.infinity, alignment: Alignment.leading)
    }
    .background(Color.white)
    .clipShape(RoundedRectangle(cornerRadius: 20))
    .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
  }

  private func speakerNames(_ speakers: [Speaker]) -> String {
    var names: [String] = []
    for speaker in speakers {
      names.append(speaker.name)
    }
    return names.joined(separator: ", ")
  }

  // MARK: - Normal Schedule Content

  @ViewBuilder
  private var normalScheduleContent: some View {
    ScrollView {
      VStack(spacing: 16) {
        scheduleHeader

        dayPicker

        if viewModel.isLoading {
          ProgressView()
            .padding()
        } else if let error = viewModel.errorMessage {
          Text(error)
            .foregroundStyle(Color.red)
            .padding()
        } else if let conference = viewModel.currentConference {
          conferenceList(conference: conference)
        }
      }
      .padding(.top, 8)
    }
    .background(screenBackground)
  }

  private var scheduleHeader: some View {
    HStack(alignment: .top, spacing: 14) {
      Image(systemName: "calendar.badge.clock")
        .font(.title2)
        .foregroundStyle(accentColor)
        .frame(width: 44, height: 44)
        .background(accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))

      VStack(alignment: .leading, spacing: 6) {
        Text("Schedule")
          .font(.title2.bold())
        Text("try! Swift Tokyo \(viewModel.selectedYear)")
          .font(.subheadline)
          .foregroundStyle(.secondary)

        if let conference = viewModel.currentConference {
          Text(conference.date, style: .date)
            .font(.footnote.weight(.semibold))
            .foregroundStyle(accentColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(accentColor.opacity(0.10), in: Capsule())
        }
      }

      Spacer()
    }
    .padding(18)
    .background(cardBackground)
    .clipShape(RoundedRectangle(cornerRadius: 20))
    .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 3)
    .padding(.horizontal)
  }

  // MARK: - Day Picker

  private var dayPicker: some View {
    Picker("Days", selection: $viewModel.selectedDay) {
      Text(ScheduleDay.day1.rawValue).tag(ScheduleDay.day1 as ScheduleDay)
      Text(ScheduleDay.day2.rawValue).tag(ScheduleDay.day2 as ScheduleDay)
      if viewModel.hasDay3 {
        Text(ScheduleDay.day3.rawValue).tag(ScheduleDay.day3 as ScheduleDay)
      }
    }
    .pickerStyle(.segmented)
    .padding(Edge.Set.horizontal)
    .tint(accentColor)
  }

  // MARK: - Conference List

  private func conferenceList(conference: Conference) -> some View {
    VStack(alignment: HorizontalAlignment.leading, spacing: 16) {
      ForEach(Array(conference.schedules.enumerated()), id: \.element.time) { index, schedule in
        scheduleSection(schedule: schedule, isLive: viewModel.liveScheduleIndex == index)
      }
    }
    .padding(.horizontal)
    .padding(.bottom, 20)
  }

  private func scheduleSection(schedule: SharedModels.Schedule, isLive: Bool) -> some View {
    VStack(alignment: HorizontalAlignment.leading, spacing: 8) {
      HStack(spacing: 6) {
        let endTimeText: String = {
          if let endTime = schedule.endTime {
            return " - " + endTime.formatted(date: .omitted, time: .shortened)
          }
          return ""
        }()
        Text(
          schedule.time.formatted(date: .omitted, time: .shortened) + endTimeText
        )
        .font(Font.subheadline.bold())
        if isLive {
          Text("LIVE")
            .font(Font.caption2.bold())
            .foregroundStyle(Color.white)
            .padding(Edge.Set.horizontal, 6)
            .padding(Edge.Set.vertical, 2)
            .background(Color.red, in: Capsule())
        }
      }

      ForEach(schedule.sessions, id: \.title) { session in
        if session.description != nil {
          Button {
            viewModel.selectSession(session)
          } label: {
            if session.title == "Office hour", let speakers = session.speakers {
              officeHourRow(session: session, speakers: speakers)
            } else {
              SessionRowView(
                session: session,
                isFavorite: viewModel.isFavorite(proposalId: session.proposalId),
                favoriteCount: viewModel.favoriteCount(proposalId: session.proposalId),
                onToggleFavorite: session.proposalId != nil
                  ? { viewModel.toggleFavorite(proposalId: session.proposalId!) } : nil
              )
            }
          }
          .buttonStyle(.plain)
        } else {
          if session.title == "Office hour", let speakers = session.speakers {
            officeHourRow(session: session, speakers: speakers)
          } else {
            SessionRowView(session: session)
          }
        }
      }
    }
    .padding(16)
    .background(cardBackground)
    .clipShape(RoundedRectangle(cornerRadius: 18))
    .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 3)
  }

  // MARK: - Office Hour

  @ViewBuilder
  private func officeHourRow(session: Session, speakers: [Speaker]) -> some View {
    let names = speakerNames(speakers)
    HStack(spacing: 12) {
      VStack(spacing: 4) {
        ForEach(Array(speakers.prefix(2)), id: \.name) { speaker in
          SpeakerAvatarView(speaker: speaker, size: 44)
        }
      }

      VStack(alignment: HorizontalAlignment.leading, spacing: 4) {
        Text("Office hour with \(names)")
          .font(Font.headline)
          .multilineTextAlignment(TextAlignment.leading)

        if let summary = session.summary {
          Text(summary)
            .font(Font.caption)
            .foregroundStyle(Color.gray)
            .lineLimit(2)
        }

        if let sponsor = session.sponsor {
          Text("Sponsored by \(sponsor)")
            .font(Font.caption)
            .foregroundStyle(Color.secondary)
        }
      }
      .frame(maxWidth: CGFloat.infinity, alignment: Alignment.leading)

      if session.description != nil {
        Image(systemName: "chevron.right")
          .foregroundStyle(Color.secondary)
      }
    }
    .padding()
    .background(accentColor.opacity(0.08))
    .clipShape(RoundedRectangle(cornerRadius: 16))
  }
}

#if !SKIP
  #Preview {
    ScheduleScreen()
  }
#endif
