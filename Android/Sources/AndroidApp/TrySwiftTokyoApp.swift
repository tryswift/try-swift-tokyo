import AboutFeature
import LiveTranslationFeature
import ScheduleFeature
import SponsorFeature
import SwiftUI
import VenueFeature

#if !SKIP
  @main
  struct TrySwiftTokyoApp: App {
    var body: some Scene {
      WindowGroup {
        ContentView()
      }
    }
  }
#endif

public struct ContentView: View {
  @State private var selectedTab = 0

  public init() {}

  public var body: some View {
    TabView(selection: $selectedTab) {
      ScheduleScreen()
        .tabItem {
          Label("Schedule", systemImage: "calendar")
        }
        .tag(0)

      LiveTranslationScreen()
        .tabItem {
          Label("Translation", systemImage: "envelope")
        }
        .tag(1)

      SponsorsScreen()
        .tabItem {
          Label("Sponsors", systemImage: "star")
        }
        .tag(2)

      VenueScreen()
        .tabItem {
          Label("Venue", systemImage: "location")
        }
        .tag(3)

      AboutScreen()
        .tabItem {
          Label("About", systemImage: "info.circle")
        }
        .tag(4)
    }
  }
}

#Preview {
  ContentView()
}
