import SharedModels
import SwiftUI

/// Schedule screen for Android.
/// Uses the same SwiftUI syntax as iOS - the only difference is state management
/// (iOS uses TCA, Android uses @Observable ViewModel).
public struct ScheduleScreen: View {
  @State private var viewModel = ScheduleViewModel()

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
      .searchable(text: $viewModel.searchText, isPresented: $viewModel.isSearchBarPresented)
      .navigationDestination(for: Session.self) { session in
        SessionDetailView(session: session, viewModel: viewModel)
          .navigationTitle("Session")
          #if os(iOS) || SKIP
            .navigationBarTitleDisplayMode(NavigationBarItem.TitleDisplayMode.inline)
          #endif
      }
      #if os(iOS) || SKIP
        .toolbar {
          ToolbarItem(placement: ToolbarItemPlacement.topBarTrailing) {
            timeTravelMenu()
          }
        }
      #endif
    }
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
      ContentUnavailableView.search(text: viewModel.searchText)
    } else {
      ScrollView {
        LazyVStack(alignment: HorizontalAlignment.leading, spacing: 12) {
          ForEach(results, id: \.self) { result in
            NavigationLink(value: result.session) {
              searchResultRow(result: result)
                .padding()
            }
            .buttonStyle(.plain)
          }
        }
        .padding()
      }
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
    .background(Color.secondary.opacity(0.1))
    .clipShape(RoundedRectangle(cornerRadius: 12))
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
    }
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
  }

  // MARK: - Conference List

  private func conferenceList(conference: Conference) -> some View {
    VStack(alignment: HorizontalAlignment.leading, spacing: 16) {
      Text(conference.date, style: Text.DateStyle.date)
        .font(Font.title2)
        .padding(Edge.Set.horizontal)

      ForEach(conference.schedules, id: \.time) { schedule in
        scheduleSection(schedule: schedule)
      }
    }
    .padding()
  }

  private func scheduleSection(schedule: SharedModels.Schedule) -> some View {
    VStack(alignment: HorizontalAlignment.leading, spacing: 8) {
      Text(schedule.time, style: Text.DateStyle.time)
        .font(Font.subheadline.bold())

      ForEach(schedule.sessions, id: \.title) { session in
        if session.description != nil {
          NavigationLink(value: session) {
            if session.title == "Office hour", let speakers = session.speakers {
              officeHourRow(session: session, speakers: speakers)
            } else {
              SessionRowView(
                session: session,
                isFavorite: viewModel.isFavorite(proposalId: session.proposalId),
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
      }
      .frame(maxWidth: CGFloat.infinity, alignment: Alignment.leading)

      if session.description != nil {
        Image(systemName: "chevron.right")
          .foregroundStyle(Color.secondary)
      }
    }
    .padding()
    .background(Color.secondary.opacity(0.1))
    .clipShape(RoundedRectangle(cornerRadius: 12))
  }
}

#if !SKIP
  #Preview {
    ScheduleScreen()
  }
#endif
