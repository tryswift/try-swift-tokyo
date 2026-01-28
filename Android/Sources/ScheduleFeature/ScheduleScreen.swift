import SharedModels
import SharedViews
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
              .foregroundStyle(.red)
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
          .navigationBarTitleDisplayMode(.inline)
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
        Text(day.rawValue).tag(day)
      }
    }
    .pickerStyle(.segmented)
    .padding(.horizontal)
  }

  // MARK: - Conference List

  private func conferenceList(conference: Conference) -> some View {
    VStack(alignment: .leading, spacing: 16) {
      Text(conference.date, style: .date)
        .font(.title2)
        .padding(.horizontal)

      ForEach(conference.schedules, id: \.time) { schedule in
        scheduleSection(schedule: schedule)
      }
    }
    .padding()
  }

  private func scheduleSection(schedule: SharedModels.Schedule) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(schedule.time, style: .time)
        .font(.subheadline.bold())

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

#Preview {
  ScheduleScreen()
}
