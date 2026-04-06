import AppFeature
import ComposableArchitecture
import LiveTranslationFeature
import ScheduleFeature
import SwiftUI

@main
struct ConferenceApp: App {
  let store = Store(initialState: AppReducer.State()) {
    AppReducer()
  }

  var body: some Scene {
    WindowGroup {
      AppView(store: store)
    }
    #if os(macOS) || os(visionOS)
      Window("Transcript", id: "transcript") {
        TranscriptWindowView(
          store: store.scope(state: \.liveTranslation, action: \.liveTranslation)
        )
      }
      #if os(visionOS)
        .defaultSize(width: 1000, height: 400)
        .windowStyle(.plain)
      #else
        .defaultSize(width: 600, height: 200)
      #endif
    #endif
    #if os(visionOS)
      Window("Session Detail", id: "scheduleDetail") {
        ScheduleDetailWindowView(
          store: store.scope(state: \.schedule, action: \.schedule)
        )
      }
      .defaultSize(width: 800, height: 600)
    #endif
  }
}
