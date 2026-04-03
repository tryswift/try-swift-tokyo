import AppFeature
import ComposableArchitecture
import LiveTranslationFeature
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
      WindowGroup("Transcript", id: "transcript") {
        TranscriptWindowView(
          store: store.scope(state: \.liveTranslation, action: \.liveTranslation)
        )
      }
      .defaultSize(width: 600, height: 200)
    #endif
  }
}
