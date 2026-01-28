import SwiftUI
import ScheduleFeature
import SponsorFeature
import VenueFeature
import AboutFeature

@main
struct TrySwiftTokyoApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
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
