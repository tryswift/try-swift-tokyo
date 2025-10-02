import ComposableArchitecture
import DataClient
import SharedModels
import SwiftUI

@Reducer
public struct Organizers {
  @ObservableState
  public struct State: Equatable {
    var organizers = IdentifiedArrayOf<Organizer>()
    @Presents var destination: Destination.State?

    public init(
      organizers: IdentifiedArrayOf<Organizer> = [],
      destination: Destination.State? = nil
    ) {
      self.organizers = organizers
      self.destination = destination
    }
  }

  public enum Action: ViewAction {
    case view(View)
    case destination(PresentationAction<Destination.Action>)
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

  @Reducer(state: .equatable)
  public enum Destination {
    case profile(Profile)
  }

  @Dependency(DataClient.self) var dataClient

  public var body: some ReducerOf<Organizers> {
    Reduce { state, action in
      switch action {
      case .view(.onAppear):
        let response = try! dataClient.fetchOrganizers()
        state.organizers.append(contentsOf: response)
        return .none
      case .view(._organizerTapped(let organizer)):
        return .send(.delegate(.organizerTapped(organizer)))
      case .delegate:
        return .none
      case .destination:
        return .none
      }
    }
  }
}

@ViewAction(for: Organizers.self)
public struct OrganizersView: View {

  public var store: StoreOf<Organizers>

  public var body: some View {
    List {
      ForEach(store.organizers) { organizer in
        Button {
          send(._organizerTapped(organizer))
        } label: {
          Label {
            Text(LocalizedStringKey(organizer.name), bundle: .module)
          } icon: {
            Image(organizer.imageName, bundle: .module)
              .resizable()
              .aspectRatio(contentMode: .fit)
              .clipShape(Circle())
              .accessibilityIgnoresInvertColors()
          }
        }
      }
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
