import DataClient
import DependencyExtra
import Foundation
import SharedModels
import SkipTCA
import SwiftUI

public struct SponsorsList: Reducer, Sendable {

  public struct State: Equatable, Sendable {
    public var sponsors: Sponsors?

    public init() {}
  }

  public enum Action: Equatable, Sendable, ViewAction {
    case view(View)
    case dataResponse(Sponsors?)

    public enum View: Equatable, Sendable {
      case onAppear
      case sponsorTapped(Sponsor)
    }
  }

  let fetchSponsors: @Sendable () async throws -> Sponsors
  let safari: @Sendable (URL) async -> Void

  public init(
    fetchSponsors: @escaping @Sendable () async throws -> Sponsors,
    safari: @escaping @Sendable (URL) async -> Void
  ) {
    self.fetchSponsors = fetchSponsors
    self.safari = safari
  }

  public func reduce(into state: inout State, action: Action) -> Effect<Action> {
    switch action {
    case .view(let viewAction):
      switch viewAction {
      case .onAppear:
        return .run { send in
          let sponsors = try? await fetchSponsors()
          send(SponsorsList.Action.dataResponse(sponsors))
        }
      case .sponsorTapped(let sponsor):
        guard let url = sponsor.link else { return .none }
        return .run { _ in
          await safari(url)
        }
      }

    case .dataResponse(let sponsors):
      state.sponsors = sponsors
      return .none
    }
  }
}

public struct SponsorsListView: View {
  let store: Store<SponsorsList.State, SponsorsList.Action>

  public init(store: Store<SponsorsList.State, SponsorsList.Action>) {
    self.store = store
  }

  public var body: some View {
    NavigationStack {
      root
        .onAppear {
          store.send(view: SponsorsList.Action.View.onAppear)
        }
    }
  }

  @ViewBuilder var root: some View {
    if let allPlans = store.state.sponsors?.allPlans {
      ScrollView {
        ForEach(Plan.allCases, id: \.self) { plan in
          Text(plan.rawValue.localizedCapitalized)
            .font(.title.bold())
            .padding(.top, 64)
            .foregroundStyle(.primary)
            #if !SKIP
              .accessibilityAddTraits(.isHeader)
            #endif
          LazyVGrid(
            columns: Array(repeating: plan.gridItem, count: plan.columnCount),
            spacing: 8
          ) {
            ForEach(allPlans[plan]!, id: \.self) { sponsor in
              Button {
                store.send(view: SponsorsList.Action.View.sponsorTapped(sponsor))
              } label: {
                VStack(spacing: 8) {
                  plan.image(of: sponsor)
                  if plan.showsName, let name = sponsor.name {
                    Text(name)
                      .font(plan.nameFont)
                      .foregroundStyle(.secondary)
                      .lineLimit(1)
                      .minimumScaleFactor(0.7)
                  }
                }
                .padding()
              }
              #if os(macOS)
                .buttonStyle(.plain)
              #else
                .buttonStyle(.plain)
                .glassEffectIfAvailable(.regular.interactive())
              #endif
              #if !SKIP
                .accessibilityAddTraits(.isLink)
                .accessibilityIgnoresInvertColors()
              #endif
            }
          }
        }
        .padding()
        .glassEffectContainerIfAvailable()
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
      return GridItem.init(.adaptive(minimum: 64, maximum: 128), spacing: 4, alignment: .center)
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

  var nameFont: Font {
    switch self {
    case .platinum:
      return .headline
    case .gold, .silver:
      return .subheadline
    case .bronze, .diversityAndInclusion, .community, .student:
      return .caption
    case .individual:
      return .caption2
    }
  }

  var showsName: Bool {
    switch self {
    case .individual:
      return false
    default:
      return true
    }
  }

  @ViewBuilder
  func image(of sponsor: Sponsor) -> some View {
    switch self {
    case .individual:
      Image(sponsor.imageName, bundle: .module)
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(maxWidth: 300)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        #if !SKIP
          .contentShape(RoundedRectangle(cornerRadius: 24))
        #endif
    default:
      Image(sponsor.imageName, bundle: .module)
        .resizable()
        .aspectRatio(contentMode: .fit)
        .padding()
        .background(.white)
        .frame(maxWidth: 300)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        #if !SKIP
          .contentShape(RoundedRectangle(cornerRadius: 24))
        #endif
        .compositingGroup()
    }
  }
}
