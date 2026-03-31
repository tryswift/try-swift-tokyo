import ComposableArchitecture
import DataClient
import DependencyExtra
import SharedModels
import SwiftUI

@Reducer
public struct Organizers {
  public init() {}

  @ObservableState
  public struct State: Equatable {
    var organizers = IdentifiedArrayOf<Organizer>()

    public init(
      organizers: IdentifiedArrayOf<Organizer> = []
    ) {
      self.organizers = organizers
    }
  }

  public enum Action: ViewAction {
    case view(View)
    case delegate(Delegate)

    public enum View {
      case onAppear
      case _organizerTapped(Organizer)
    }

    @CasePathable
    public enum Delegate {
      case organizerTapped(Organizer)
    }
  }

  @Dependency(DataClient.self) var dataClient

  public var body: some ReducerOf<Organizers> {
    Reduce { state, action in
      switch action {
      case .view(.onAppear):
        if let response = try? dataClient.fetchOrganizers(.latest) {
          state.organizers.append(contentsOf: response)
        }
        return .none
      case .view(._organizerTapped(let organizer)):
        return .send(.delegate(.organizerTapped(organizer)))
      case .delegate:
        return .none
      }
    }
  }
}

@ViewAction(for: Organizers.self)
public struct OrganizersView: View {

  @Bindable public var store: StoreOf<Organizers>

  public init(store: StoreOf<Organizers>) {
    self.store = store
  }

  public var body: some View {
    ScrollView {
      LazyVStack(spacing: 12) {
        ForEach(store.organizers) { organizer in
          Button {
            send(._organizerTapped(organizer))
          } label: {
            HStack(spacing: 12) {
              Image(organizer.imageName, bundle: .module)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 60, height: 60)
                .clipShape(Circle())
                .accessibilityIgnoresInvertColors()
              Text(LocalizedStringKey(organizer.name), bundle: .module)
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
          }
          .glassIfAvailable()
        }
      }
      .padding()
    }
    .onAppear {
      send(.onAppear)
    }
    .navigationTitle(Text("Meet Organizers", bundle: .module))
  }
}

#Preview {
  OrganizersView(
    store: .init(
      initialState: .init(),
      reducer: {
        Organizers()
      }))
}
