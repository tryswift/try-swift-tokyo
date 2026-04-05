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

  private let accentColor = Color(red: 0.11, green: 0.35, blue: 0.85)

  public init() {}

  public var body: some View {
    TabView(selection: $selectedTab) {
      ScheduleScreen()
        .tabItem {
          Label("Schedule", systemImage: "calendar.circle.fill")
        }
        .tag(0)

      LiveTranslationScreen()
        .tabItem {
          Label("Live", systemImage: "message.fill")
        }
        .tag(1)

      SponsorsScreen()
        .tabItem {
          Label("Sponsors", systemImage: "building.2.fill")
        }
        .tag(2)

      VenueScreen()
        .tabItem {
          Label("Venue", systemImage: "map.fill")
        }
        .tag(3)

      AboutScreen()
        .tabItem {
          Label("About", systemImage: "info.circle.fill")
        }
        .tag(4)
    }
    .tint(accentColor)
  }
}

#Preview {
  ContentView()
}
