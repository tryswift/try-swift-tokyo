import ComposableArchitecture
import Foundation
import GuidanceFeature
import ScheduleFeature
import SponsorFeature
import SwiftUI
import TipKit
import trySwiftFeature

#if canImport(LiveTranslationSDK_iOS)
  import LiveTranslationFeature
#endif

@Reducer
public struct AppReducer {
  @ObservableState
  public struct State: Equatable {
    var schedule = Schedule.State()
    var guidance = Guidance.State()
    var sponsors = SponsorsList.State()
    var trySwift = TrySwift.State()

    public init() {
      try? Tips.configure([.displayFrequency(.immediate)])
    }
  }

  public enum Action {
    case schedule(Schedule.Action)
    case guidance(Guidance.Action)
    case sponsors(SponsorsList.Action)
    case trySwift(TrySwift.Action)
  }

  public init() {}

  public var body: some ReducerOf<Self> {
    Scope(state: \.schedule, action: \.schedule) {
      Schedule()
    }
    Scope(state: \.guidance, action: \.guidance) {
      Guidance()
    }
    Scope(state: \.sponsors, action: \.sponsors) {
      SponsorsList()
    }
    Scope(state: \.trySwift, action: \.trySwift) {
      TrySwift()
    }
  }
}

public struct AppView: View {
  var store: StoreOf<AppReducer>

  public init(store: StoreOf<AppReducer>) {
    self.store = store
  }

  public var body: some View {
    TabView {
      ScheduleView(store: store.scope(state: \.schedule, action: \.schedule))
        .tabItem {
          Label(String(localized: "Schedule", bundle: .module), systemImage: "calendar")
        }
      #if canImport(LiveTranslationSDK_iOS)
        LiveTranslationView()
          .tabItem {
            Label(String(localized: "Translation", bundle: .module), systemImage: "text.bubble")
          }
      #endif
      GuidanceView(store: store.scope(state: \.guidance, action: \.guidance))
        .tabItem {
          Label(String(localized: "Venue", bundle: .module), systemImage: "map")
        }
      SponsorsListView(store: store.scope(state: \.sponsors, action: \.sponsors))
        .tabItem {
          Label(String(localized: "Sponsors", bundle: .module), systemImage: "building.2")
        }
      TrySwiftView(store: store.scope(state: \.trySwift, action: \.trySwift))
        .tabItem {
          Image(.rikoTokyo)
          Text("About", bundle: .module)
        }
    }
  }
}

#Preview {
  AppView(
    store: .init(
      initialState: .init(),
      reducer: {
        AppReducer()
      }))
}
