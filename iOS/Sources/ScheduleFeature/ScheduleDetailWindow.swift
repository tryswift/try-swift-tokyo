#if os(visionOS)
  import ComposableArchitecture
  import SwiftUI
  import VideoFeature

  public struct ScheduleDetailWindowView: View {

    let store: StoreOf<Schedule>

    public init(store: StoreOf<Schedule>) {
      self.store = store
    }

    public var body: some View {
      Group {
        if let detailStore = store.scope(
          state: \.destination?.detail, action: \.destination.detail)
        {
          NavigationStack {
            ScheduleDetailView(store: detailStore)
          }
        } else if let videoStore = store.scope(
          state: \.destination?.videoDetail, action: \.destination.videoDetail)
        {
          NavigationStack {
            VideoDetailView(store: videoStore, speakerImageBundle: scheduleFeatureBundle)
          }
        } else {
          ContentUnavailableView {
            Label(
              String(localized: "Select a Session", bundle: .module),
              systemImage: "text.document")
          }
        }
      }
      .onDisappear {
        store.send(.destination(.dismiss))
      }
    }
  }
#endif
