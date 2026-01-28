import ComposableArchitecture
import DataClient
import DependencyExtra
import SharedModels
import SwiftUI

@Reducer
public struct TrySwift: Sendable {
  @ObservableState
  public struct State: Equatable {
    var path = StackState<Path.State>()

    public init(
      path: StackState<Path.State> = .init()
    ) {
      self.path = path
    }
  }

  public enum Action: BindableAction, ViewAction {
    case path(StackAction<Path.State, Path.Action>)
    case binding(BindingAction<State>)
    case view(View)

    @CasePathable
    public enum View {
      case organizerTapped
      case codeOfConductTapped
      case acknowledgementsTapped
      case privacyPolicyTapped
      case ticketTapped
      case websiteTapped
    }
  }

  @Reducer
  public enum Path {
    case organizers(Organizers)
    case profile(Profile)
    case acknowledgements(Acknowledgements)
  }

  @Dependency(\.safari) var safari

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
        return .run { _ in await safari(url) }
      case .view(.privacyPolicyTapped):
        let url = URL(string: String(localized: "Privacy Policy URL", bundle: .module))!
        return .run { _ in await safari(url) }
      case .view(.acknowledgementsTapped):
        state.path.append(.acknowledgements(.init()))
        return .none
      case .view(.ticketTapped):
        let url = URL(string: String(localized: "Luma URL", bundle: .module))!
        return .run { _ in await safari(url) }
      case .view(.websiteTapped):
        let url = URL(string: String(localized: "Website URL", bundle: .module))!
        return .run { _ in await safari(url) }
      case .path(.element(_, .organizers(.delegate(.organizerTapped(let organizer))))):
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

extension TrySwift.Path.State: Equatable {}

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
    ScrollView {
      VStack(spacing: 20) {
        // Logo Section
        VStack(spacing: 16) {
          Image("logo", bundle: .module)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(maxWidth: 300)
            .accessibilityIgnoresInvertColors()
          Text("try! Swift Description", bundle: .module)
            .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .glassEffect(.clear, in: .rect(cornerRadius: 20))

        // Legal Section
        VStack(spacing: 12) {
          Button {
            send(.codeOfConductTapped)
          } label: {
            HStack {
              Text("Code of Conduct", bundle: .module)
              Spacer()
              Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
            }
            .padding()
          }
          .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 12))

          Button {
            send(.privacyPolicyTapped)
          } label: {
            HStack {
              Text("Privacy Policy", bundle: .module)
              Spacer()
              Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
            }
            .padding()
          }
          .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 12))
        }

        // Team Section
        VStack(spacing: 12) {
          Button {
            send(.organizerTapped)
          } label: {
            HStack {
              Text("Organizers", bundle: .module)
              Spacer()
              Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
            }
            .padding()
          }
          .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 12))

          Button {
            send(.acknowledgementsTapped)
          } label: {
            HStack {
              Text("Acknowledgements", bundle: .module)
              Spacer()
              Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
            }
            .padding()
          }
          .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 12))
        }

        // Links Section
        VStack(spacing: 12) {
          Button {
            send(.ticketTapped)
          } label: {
            HStack {
              Text("Luma", bundle: .module)
              Spacer()
              Image(systemName: "arrow.up.right")
                .foregroundStyle(.secondary)
            }
            .padding()
          }
          .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 12))

          Button {
            send(.websiteTapped)
          } label: {
            HStack {
              Text("try! Swift Website", bundle: .module)
              Spacer()
              Image(systemName: "arrow.up.right")
                .foregroundStyle(.secondary)
            }
            .padding()
          }
          .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 12))
        }
      }
      .padding()
    }
    .navigationTitle(Text("try! Swift", bundle: .module))
  }
}

#Preview {
  TrySwiftView(
    store: .init(initialState: .init()) {
      TrySwift()
    })
}
