import AboutFeature
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

      SponsorsScreen()
        .tabItem {
          Label("Sponsors", systemImage: "building.2")
        }
        .tag(1)

      VenueScreen()
        .tabItem {
          Label("Venue", systemImage: "map")
        }
        .tag(2)

      AboutScreen()
        .tabItem {
          Label("About", systemImage: "info.circle")
        }
        .tag(3)
    }
  }
}

#Preview {
  ContentView()
}
