import ComposableArchitecture
import DataClient
import DependencyExtra
import Foundation
import SharedModels
import SwiftUI

@Reducer
public struct SponsorsList {
  @ObservableState
  public struct State: Equatable {

    var searchText: String = ""
    var isSearchBarPresented: Bool = false
    var sponsors: Sponsors?
    @Presents var destination: Destination.State?

    public init() {}
  }

  public enum Action: ViewAction {
    case destination(PresentationAction<Destination.Action>)
    case view(View)
    case sponsorResponse(Result<Sponsors, Error>)

    @CasePathable
    public enum View: BindableAction, Sendable {
      case binding(BindingAction<State>)
      case onAppear
      case sponsorTapped(Sponsor)
    }
  }

  public init() {}

  public var body: some ReducerOf<Self> {
    BindingReducer(action: \.view)
    Reduce<State, Action> { state, action in
      switch action {
      case .view(.onAppear):
        @Dependency(DataClient.self) var dataClient
        return .run { send in
          await send(
            .sponsorResponse(Result { try await dataClient.fetchSponsors() })
          )
        }
      case let .view(.sponsorTapped(sponsor)):
        guard let url = sponsor.link else { return .none }
        return .run { _ in
          @Dependency(\.safari) var safari
          await safari(url)
        }
      case .view(.binding):
        return .none
      case let .sponsorResponse(.success(response)):
        state.sponsors = response
        return .none
      case .sponsorResponse(.failure):
        return .none
      case .destination:
        return .none
      }
    }
    .ifLet(\.$destination, action: \.destination)
  }

  @Reducer(state: .equatable)
  public enum Destination {
  }
}

@ViewAction(for: SponsorsList.self)
public struct SponsorsListView: View {
  @Bindable public var store: StoreOf<SponsorsList>

  public init(store: StoreOf<SponsorsList>) {
    self.store = store
  }

  public var body: some View {
    NavigationView {
      root
        .onAppear {
          send(.onAppear)
        }
    }
    .navigationViewStyle(.stack)
  }

  @ViewBuilder var root: some View {
    if let allPlans = store.sponsors?.allPlans {
      ScrollView {
        ForEach(Plan.allCases, id: \.self) { plan in
          Text(plan.rawValue.localizedCapitalized)
            .font(.title.bold())
            .padding(.top, 64)
            .foregroundStyle(Color.black)
          LazyVGrid(
            columns: Array(repeating: plan.gridItem, count: plan.columnCount),
            spacing: 64
          ) {
            ForEach(allPlans[plan]!, id: \.self) { sponsor in
              Image(sponsor.imageName, bundle: .module)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: 300)
                .onTapGesture {
                  send(.sponsorTapped(sponsor))
                }
            }
          }
          .background(Color.white)
        }
        .padding()
        .background(Color.white)
      }
      .navigationTitle(Text("Sponsors", bundle: .module))
    } else {
      ProgressView()
    }
  }
}

extension Plan {
  var gridItem: GridItem {
    switch self {
    case .platinum:
      return GridItem(.flexible(minimum: 320, maximum: 1024), spacing: 64, alignment: .center)
    case .gold, .silver, .bronze, .diversityAndInclusion, .community, .student:
      return GridItem(.flexible(minimum: 64, maximum: 512), spacing: 64, alignment: .center)
    case .individual:
      return GridItem.init(.adaptive(minimum: 64, maximum: 128), spacing: 32, alignment: .center)
    }

  }
  var columnCount: Int {
    switch self {
    case .platinum:
      return 1
    case .gold, .silver, .bronze, .diversityAndInclusion, .community, .student:
      return 2
    case .individual:
      return 4
    }
  }
}
