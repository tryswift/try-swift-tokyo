import ComposableArchitecture
import DependencyExtra
import Foundation
import SharedModels
import SwiftUI

@Reducer
public struct ScheduleDetail {
  @ObservableState
  public struct State: Equatable {

    var title: String
    var description: String
    var requirements: String?
    var speakers: [Speaker]

    public init(
      title: String, description: String, requirements: String? = nil, speakers: [Speaker]
    ) {
      self.title = title
      self.description = description
      self.requirements = requirements
      self.speakers = speakers
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

@ViewAction(for: ScheduleDetail.self)
public struct ScheduleDetailView: View {

  @Bindable public var store: StoreOf<ScheduleDetail>

  public init(store: StoreOf<ScheduleDetail>) {
    self.store = store
  }

  public var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        Text(LocalizedStringKey(store.title), bundle: .module)
          .font(.title.bold())
          .accessibilityAddTraits(.isHeader)
        Text(LocalizedStringKey(store.description), bundle: .module)
          .font(.callout)
        if let requirements = store.requirements {
          VStack(alignment: .leading) {
            Text("Requirements", bundle: .module)
              .font(.subheadline.bold())
              .foregroundStyle(Color.accentColor)
            Text(LocalizedStringKey(requirements), bundle: .module)
              .font(.callout)
          }
          .padding()
          .overlay {
            RoundedRectangle(cornerRadius: 16)
              .stroke(Color.accentColor, lineWidth: 1)
          }
        }
      }
      .padding(.horizontal)
      .padding(.bottom)
      .frame(maxWidth: 700)  // Readable content width for iPad

      speakers
        .frame(maxWidth: 700)  // Readable content width for iPad
    }
  }

  @ViewBuilder
  var speakers: some View {
    VStack {
      ForEach(store.speakers, id: \.self) { speaker in
        VStack(spacing: 16) {
          HStack {
            Image(speaker.imageName, bundle: .module)
              .resizable()
              .aspectRatio(1.0, contentMode: .fit)
              .frame(width: 60)
              .clipShape(Circle())
              .accessibilityIgnoresInvertColors()
            VStack {
              Text(LocalizedStringKey(speaker.name), bundle: .module)
                .font(.title3.bold())
                .frame(maxWidth: .infinity, alignment: .leading)
              if let links = speaker.links {
                HStack {
                  ForEach(links, id: \.self) { link in
                    Button(link.name) {
                      send(.snsTapped(link.url))
                    }
                    .accessibilityAddTraits(.isLink)
                  }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
              }
            }
          }
          if let bio = speaker.bio {
            Text(LocalizedStringKey(bio), bundle: .module)
              .frame(maxWidth: .infinity, alignment: .leading)
          }
        }
      }
    }
    .padding()
    .background(
      secondarySystemBackgroundColor
        .clipShape(RoundedRectangle(cornerRadius: 8))
    )
    .padding()

  }

  private var secondarySystemBackgroundColor: Color {
    #if os(macOS)
      Color(nsColor: .underPageBackgroundColor)
    #else
      Color(uiColor: .secondarySystemBackground)
    #endif
  }
}

#Preview {
  ScheduleDetailView(
    store: .init(
      initialState: .init(
        title: "What's new in try! Swift",
        description: #"""
          try! Swift is an international community gathering that focuses on the Swift programming language and its ecosystem. It brings together developers, industry experts, and enthusiasts for a series of talks, learning sessions, and networking opportunities. The event aims to foster collaboration, share the latest advancements and best practices, and inspire innovation within the Swift community.The revival of "try! Swift" signifies a renewed commitment to these goals, potentially after a period of hiatus or reduced activity, possibly due to global challenges like the COVID-19 pandemic. This resurgence would likely involve the organization of new events, either virtually or in-person, reflecting the latest trends and technologies within the Swift ecosystem. The revival indicates a strong, ongoing interest in Swift programming, with the community eager to reconvene, exchange ideas, and continue learning from each other.
          """#,
        speakers: [
          Speaker(
            name: "Natasha Murashev",
            imageName: "natasha",
            bio:
              "Natasha is an iOS developer by day and a robot by night. She organizes the try! Swift Conference around the world (including this one!). She's currently living the digital nomad life as her alter identity: @natashatherobot",
            links: [
              .init(
                name: "@natashatherobot",
                url: URL(string: "https://x.com/natashatherobot")!
              )
            ]
          )
        ]
      ),
      reducer: {
        ScheduleDetail()
      }
    )
  )
}
