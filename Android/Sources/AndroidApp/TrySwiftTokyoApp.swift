import AboutFeature
import AndroidLiveTranslationFeature
import AndroidScheduleFeature
import DataClient
import DependencyExtra
import SkipTCA
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

  // SkipTCA store wired against the shared SponsorsList feature in Conference.
  // Tabs that have not been migrated yet still use the local Android-only
  // implementations under Android/Sources/<Feature>; they will be replaced as
  // each feature graduates to SkipTCA.
  @State private var sponsorsStore: SkipTCA.Store<SponsorsList.State, SponsorsList.Action> =
    ContentView.makeSponsorsStore()

  public init() {}

  private static func makeSponsorsStore() -> SkipTCA.Store<SponsorsList.State, SponsorsList.Action>
  {
    let reducer = SponsorsList(
      fetchSponsors: { try DataClient.live.fetchSponsors(.latest) },
      safari: { url in await SafariEffect.live(url) }
    )
    return SkipTCA.Store(
      initialState: SponsorsList.State(),
      reducer: { state, action in
        reducer.reduce(into: &state, action: action)
      }
    )
  }

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

      SponsorsListView(store: sponsorsStore)
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
