import ComposableArchitecture
import DependencyExtra
import SwiftUI

@Reducer
public struct Acknowledgements {
  @ObservableState
  public struct State: Equatable {
    var packages = LicenseProvider.packages

    public init() {}
  }

  public enum Action {
    case urlTapped(URL)
  }

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case let .urlTapped(url):
        @Dependency(\.safari) var safari
        return .run { _ in await safari(url) }
      }
    }
  }
}

public struct AcknowledgementsView: View {

  @Bindable public var store: StoreOf<Acknowledgements>

  public var body: some View {
    List {
      ForEach(store.packages, id: \.self) { package in
        NavigationLink(package.name) {
          ScrollView {
            Button(package.location.absoluteString) {
              store.send(.urlTapped(package.location))
            }
            .padding()
            Text(package.license)
              .padding()
          }
          .navigationTitle(package.name)
        }
      }
    }
    .navigationTitle(Text("Acknowledgements", bundle: .module))
  }
}

#Preview {
  NavigationStack {
    AcknowledgementsView(
      store: .init(initialState: .init()) {
        Acknowledgements()
      })
  }
}
