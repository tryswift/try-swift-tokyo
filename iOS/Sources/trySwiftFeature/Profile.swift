import ComposableArchitecture
import DependencyExtra
import Foundation
import SharedModels
import SwiftUI

@Reducer
public struct Profile: Sendable {
  @ObservableState
  public struct State: Equatable {
    var organizer: Organizer

    public init(organizer: Organizer) {
      self.organizer = organizer
    }
  }

  public enum Action: ViewAction, BindableAction {
    case binding(BindingAction<State>)
    case view(View)

    public enum View {
      case snsTapped(URL)
    }
  }

  @Dependency(\.safari) var safari

  public init() {}

  public var body: some ReducerOf<Self> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case .view(.snsTapped(let url)):
        return .run { _ in await safari(url) }
      case .binding:
        return .none
      }
    }
  }
}

@ViewAction(for: Profile.self)
public struct ProfileView: View {

  @Bindable public var store: StoreOf<Profile>

  public init(store: StoreOf<Profile>) {
    self.store = store
  }

  public var body: some View {
    ScrollView {
      VStack(spacing: 16) {
        VStack {
          Image(store.organizer.imageName, bundle: .module)
            .resizable()
            .aspectRatio(1.0, contentMode: .fill)
            .frame(maxWidth: 400)
            .accessibilityIgnoresInvertColors()
          VStack {
            if let links = store.organizer.links {
              HStack {
                ForEach(links, id: \.self) { link in
                  Button(link.name) {
                    send(.snsTapped(link.url))
                  }
                }
              }
              .frame(maxWidth: .infinity, alignment: .leading)
              .padding()
            }
          }
        }
        Text(LocalizedStringKey(store.organizer.bio), bundle: .module)
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding()
          .frame(maxWidth: 700)
      }
      .navigationTitle(Text(LocalizedStringKey(store.organizer.name), bundle: .module))
    }
  }
}

#Preview {
  NavigationStack {
    ProfileView(
      store: .init(
        initialState: .init(organizer: .trySwift)
      ) {
        Profile()
      })
  }
}

extension Organizer {
  static fileprivate let trySwift: Self = .init(
    id: 1,
    name: "try! Swift",
    imageName: "logo",
    bio: #"""
      try! Swift is an international community gathering that focuses on the Swift programming language and its ecosystem. It brings together developers, industry experts, and enthusiasts for a series of talks, learning sessions, and networking opportunities. The event aims to foster collaboration, share the latest advancements and best practices, and inspire innovation within the Swift community.The revival of "try! Swift" signifies a renewed commitment to these goals, potentially after a period of hiatus or reduced activity, possibly due to global challenges like the COVID-19 pandemic. This resurgence would likely involve the organization of new events, either virtually or in-person, reflecting the latest trends and technologies within the Swift ecosystem. The revival indicates a strong, ongoing interest in Swift programming, with the community eager to reconvene, exchange ideas, and continue learning from each other.
      """#,
    links: [
      .init(
        name: "@tryswiftconf",
        url: URL(string: "https://twitter.com/tryswiftconf")!
      ),
      .init(
        name: "try! Swift Tokyo(tryswift.jp)",
        url: URL(string: "https://tryswift.jp")!
      ),
      .init(
        name: "#tryswift",
        url: URL(string: "https://twitter.com/search?q=%23tryswift")!
      ),
    ]
  )
}
