import ComposableArchitecture
import DependencyExtra
import SwiftUI

@Reducer
public struct Acknowledgements: Sendable {
  @ObservableState
  public struct State: Equatable {
    var packages = LicensesPlugin.licenses

    public init() {}
  }

  public enum Action {
    case urlTapped(URL)
  }

  @Dependency(\.safari) var safari

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .urlTapped(let url):
        return .run { _ in await safari(url) }
      }
    }
  }
}

public struct AcknowledgementsView: View {

  @Bindable public var store: StoreOf<Acknowledgements>
  public var body: some View {
    List {
      ForEach(LicensesPlugin.licenses) { license in
        NavigationLink(license.name) {
          VStack {
            if let licenseText = license.licenseText {
              ScrollView {
                Text(licenseText)
                  .padding()
              }
            } else {
              Text("No License Found")
            }
          }
          .navigationTitle(license.name)
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
