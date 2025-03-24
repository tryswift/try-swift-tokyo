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
    case organizersResponse(Result<[Organizer], Error>)

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

  public var body: some ReducerOf<Organizers> {
    Reduce { state, action in
      switch action {
      case .view(.onAppear):
        @Dependency(DataClient.self) var dataClient
        
        return .run { send in
          await send(
            .organizersResponse(Result { try await  dataClient.fetchOrganizers()})
          )
        }
      case let .organizersResponse(.success(response)):
        state.organizers.append(contentsOf: response)
        return .none
      case .organizersResponse(.failure):
        return .none
      case let .view(._organizerTapped(organizer)):
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
