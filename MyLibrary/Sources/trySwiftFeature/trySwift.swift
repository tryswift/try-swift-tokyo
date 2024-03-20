import ComposableArchitecture
import DataClient
import Safari
import SharedModels
import SwiftUI

@Reducer
public struct TrySwift {
  @ObservableState
  public struct State: Equatable {
    var path = StackState<Path.State>()
    public init() {}
  }

  public enum Action: BindableAction, ViewAction {
    case path(StackAction<Path.State, Path.Action>)
    case binding(BindingAction<State>)
    case view(View)

    public enum View {
      case organizerTapped
      case codeOfConductTapped
      case acknowledgementsTapped
      case privacyPolicyTapped
      case eventbriteTapped
      case websiteTapped
    }
  }

  @Reducer(state: .equatable)
  public enum Path {
    case organizers(Organizers)
    case profile(Profile)
    case acknowledgements(Acknowledgements)
  }

  @Dependency(\.openURL) var openURL

  public init() {}

  public var body: some ReducerOf<TrySwift> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case .view(.organizerTapped):
        state.path.append(.organizers(.init()))
        return .none
      case .view(.codeOfConductTapped):
        let url = URL(string: String(localized: "Code of Conduct URL", bundle: .module))!
        let canOpenInSafari = UIApplication.shared.openInSFSafariViewIfEnabled(url: url)
        if canOpenInSafari {
          return .none
        }
        return .run { _ in await openURL(url) }
      case .view(.privacyPolicyTapped):
        let url = URL(string: String(localized: "Privacy Policy URL", bundle: .module))!
        let canOpenInSafari = UIApplication.shared.openInSFSafariViewIfEnabled(url: url)
        if canOpenInSafari {
          return .none
        }
        return .run { _ in await openURL(url) }
      case .view(.acknowledgementsTapped):
        state.path.append(.acknowledgements(.init()))
        return .none
      case .view(.eventbriteTapped):
        let url = URL(string: String(localized: "Eventbrite URL", bundle: .module))!
        let canOpenInSafari = UIApplication.shared.openInSFSafariViewIfEnabled(url: url)
        if canOpenInSafari {
          return .none
        }
        return .run { _ in await openURL(url) }
      case .view(.websiteTapped):
        let url = URL(string: String(localized: "Website URL", bundle: .module))!
        let canOpenInSafari = UIApplication.shared.openInSFSafariViewIfEnabled(url: url)
        if canOpenInSafari {
          return .none
        }
        return .run { _ in await openURL(url) }
      case let .path(.element(_, .organizers(.delegate(.organizerTapped(organizer))))):
        state.path.append(.profile(.init(organizer: organizer)))
        return .none
      case .binding:
        return .none
      case .path:
        return .none
      }
    }
    .forEach(\.path, action: \.path)
  }
}

@ViewAction(for: TrySwift.self)
public struct TrySwiftView: View {

  @Bindable public var store: StoreOf<TrySwift>

  public init(store: StoreOf<TrySwift>) {
    self.store = store
  }

  public var body: some View {
    NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
      root
    } destination: { store in
      switch store.state {
      case .organizers:
        if let store = store.scope(state: \.organizers, action: \.organizers) {
          OrganizersView(store: store)
        }
      case .profile:
        if let store = store.scope(state: \.profile, action: \.profile) {
          ProfileView(store: store)
        }
      case .acknowledgements:
        if let store = store.scope(state: \.acknowledgements, action: \.acknowledgements) {
          AcknowledgementsView(store: store)
        }
      }
    }
    .navigationTitle(Text("try! Swift", bundle: .module))
  }

  @ViewBuilder var root: some View {
    List {
      Section {
        HStack {
          Spacer()
          Image("logo", bundle: .module)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(maxWidth: 400, alignment: .center)
          Spacer()
        }
        Text("try! Swift Description", bundle: .module)
      }
      Section {
        Button {
          send(.codeOfConductTapped)
        } label: {
          Text("Code of Conduct", bundle: .module)
        }
        Button {
          send(.privacyPolicyTapped)
        } label: {
          Text("Privacy Policy", bundle: .module)
        }
      }
      Section {
        Button {
          send(.organizerTapped)
        } label: {
          Text("Organizers", bundle: .module)
        }
        Button {
          send(.acknowledgementsTapped)
        } label: {
          Text("Acknowledgements", bundle: .module)
        }
      }
      Section {
        Button {
          send(.eventbriteTapped)
        } label: {
          Text("Eventbrite", bundle: .module)
        }
        Button {
          send(.websiteTapped)
        } label: {
          Text("try! Swift Website", bundle: .module)
        }
      }
    }
    .navigationTitle(Text("try! Swift", bundle: .module))
  }
}
