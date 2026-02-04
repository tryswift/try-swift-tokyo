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
      .navigationTitle("Schedule")
      .navigationDestination(for: Session.self) { session in
        // Uses shared SessionDetailView - identical code on iOS and Android
        SessionDetailView(session: session)
          .navigationTitle("Session")
          #if os(iOS) || SKIP
          .navigationBarTitleDisplayMode(NavigationBarItem.TitleDisplayMode.inline)
          #endif
      }
    }
    .onAppear {
      viewModel.loadSchedules()
    }
  }

  // MARK: - Day Picker (identical SwiftUI syntax on both platforms)

  private var dayPicker: some View {
    Picker("Days", selection: $viewModel.selectedDay) {
      ForEach(ScheduleDay.allCases) { day in
        Text(day.rawValue).tag(day as ScheduleDay)
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
        // Uses shared SessionRowView - identical code on iOS and Android
        if session.description != nil {
          NavigationLink(value: session) {
            SessionRowView(session: session)
          }
          .buttonStyle(.plain)
        } else {
          SessionRowView(session: session)
        }
      }
    }
  }
}

#if !SKIP
#Preview {
  ScheduleScreen()
}
#endif
