import ComposableArchitecture
import DependencyExtra
import Foundation
import SharedModels
import SwiftUI

public struct RelatedSession: Equatable, Hashable, Identifiable, Sendable {
  public var id: String { "\(year.rawValue)-\(session.title)" }
  public var year: ConferenceYear
  public var session: Session
  public var speakerImageName: String?
  public var speakerName: String?
  public var isSameSpeaker: Bool
}

@Reducer
public struct ScheduleDetail: Sendable {
  @ObservableState
  public struct State: Equatable {

    var proposalId: String?
    var isFavorite: Bool = false
    var favoriteCount: Int = 0
    var title: String
    var description: String
    var requirements: String?
    var speakers: [Speaker]
    var relatedSessions: [RelatedSession] = []

    // Feedback
    var feedbackText: String = ""
    var feedbackSubmitted: Bool = false
    var isSubmittingFeedback: Bool = false
    var feedbackError: String?

    public init(
      proposalId: String? = nil,
      isFavorite: Bool = false,
      favoriteCount: Int = 0,
      title: String,
      description: String,
      requirements: String? = nil,
      speakers: [Speaker],
      relatedSessions: [RelatedSession] = []
    ) {
      self.proposalId = proposalId
      self.isFavorite = isFavorite
      self.favoriteCount = favoriteCount
      self.title = title
      self.description = description
      self.requirements = requirements
      self.speakers = speakers
      self.relatedSessions = relatedSessions
    }
  }

  public enum Action: ViewAction, BindableAction {
    case binding(BindingAction<State>)
    case view(View)
    case feedbackSubmitResponse(Result<Bool, Error>)
    case favoriteToggled(Bool, Int)
    case delegate(Delegate)

    public enum View {
      case snsTapped(URL)
      case favoriteTapped
      case submitFeedbackTapped
      case relatedSessionTapped(RelatedSession)
    }

    public enum Delegate: Equatable {
      case showRelatedSession(Session, ConferenceYear)
    }
  }

  @Dependency(\.safari) var safari
  @Dependency(\.scheduleAPIClient) var apiClient

  public init() {}

  public var body: some ReducerOf<Self> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case .view(.relatedSessionTapped(let related)):
        return .send(.delegate(.showRelatedSession(related.session, related.year)))
      case .view(.snsTapped(let url)):
        return .run { _ in await safari(url) }
      case .view(.favoriteTapped):
        guard let proposalId = state.proposalId else { return .none }
        let previousIsFavorite = state.isFavorite
        let previousCount = state.favoriteCount
        state.isFavorite.toggle()
        let apiClient = apiClient
        return .run { send in
          let result = try await apiClient.toggleFavorite(
            proposalId, DeviceIdentifier.current)
          await send(.favoriteToggled(result.isFavorite, result.count))
        } catch: { _, send in
          await send(.favoriteToggled(previousIsFavorite, previousCount))
        }
      case .favoriteToggled(let isFavorite, let count):
        state.isFavorite = isFavorite
        state.favoriteCount = count
        return .none
      case .view(.submitFeedbackTapped):
        guard let proposalId = state.proposalId else { return .none }
        let comment = state.feedbackText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !comment.isEmpty else { return .none }
        state.isSubmittingFeedback = true
        state.feedbackError = nil
        let apiClient = apiClient
        return .run { send in
          try await apiClient.submitFeedback(proposalId, comment, DeviceIdentifier.current)
          await send(.feedbackSubmitResponse(.success(true)))
        } catch: { error, send in
          await send(.feedbackSubmitResponse(.failure(error)))
        }
      case .feedbackSubmitResponse(.success):
        state.isSubmittingFeedback = false
        state.feedbackSubmitted = true
        state.feedbackText = ""
        return .none
      case .feedbackSubmitResponse(.failure(let error)):
        state.isSubmittingFeedback = false
        state.feedbackError = error.localizedDescription
        return .none
      case .binding, .delegate:
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
          .glassEffectIfAvailable(.regular.tint(.accentColor), in: .rect(cornerRadius: 16))
        }
      }
      .padding()
      .frame(maxWidth: 700)  // Readable content width for iPad

      speakers
        .frame(maxWidth: 700)  // Readable content width for iPad

      if !store.relatedSessions.isEmpty {
        relatedSessionsSection
          .frame(maxWidth: 700)
      }

      if store.proposalId != nil {
        feedbackSection
          .frame(maxWidth: 700)
      }
    }
    .toolbar {
      if store.proposalId != nil {
        #if os(macOS)
          ToolbarItem(placement: .primaryAction) {
            favoriteToolbarButton
          }
        #else
          ToolbarItem(placement: .topBarTrailing) {
            favoriteToolbarButton
          }
        #endif
      }
    }
  }

  @ViewBuilder
  var favoriteToolbarButton: some View {
    Button {
      send(.favoriteTapped)
    } label: {
      HStack(spacing: 2) {
        Image(systemName: store.isFavorite ? "heart.fill" : "heart")
          .foregroundStyle(store.isFavorite ? Color.red : Color.secondary)
        if store.favoriteCount > 0 {
          Text("\(store.favoriteCount)")
            .font(.caption2)
            .foregroundStyle(store.isFavorite ? Color.red : Color.secondary)
        }
      }
    }
    .accessibilityLabel(store.isFavorite ? "Remove from favorites" : "Add to favorites")
    .accessibilityValue(store.favoriteCount > 0 ? "\(store.favoriteCount)" : "")
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
    .glassEffectIfAvailable(.regular, in: .rect(cornerRadius: 16))
    .padding()
  }

  @ViewBuilder
  var relatedSessionsSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Related Sessions", bundle: .module)
        .font(.title3.bold())
        .padding(.horizontal)

      ForEach(store.relatedSessions) { related in
        Button {
          send(.relatedSessionTapped(related))
        } label: {
          relatedSessionRow(related)
            .padding()
        }
        .glassIfAvailable()
      }
    }
    .padding()
    .glassEffectContainerIfAvailable()
  }

  @ViewBuilder
  func relatedSessionRow(_ related: RelatedSession) -> some View {
    HStack(spacing: 8) {
      if let imageName = related.speakerImageName {
        Image(imageName, bundle: .module)
          .resizable()
          .aspectRatio(contentMode: .fit)
          .clipShape(Circle())
          .frame(width: 44)
          .accessibilityIgnoresInvertColors()
      }
      VStack(alignment: .leading, spacing: 2) {
        Text(LocalizedStringKey(related.session.title), bundle: .module)
          .font(.body)
          .multilineTextAlignment(.leading)
        if let speakerName = related.speakerName {
          Text(speakerName)
            .font(.caption)
            .foregroundStyle(labelColor)
        }
        Text(String(related.year.rawValue))
          .font(.caption2)
          .foregroundStyle(secondaryLabelColor)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .accessibilityElement(children: .combine)
    }
  }

  private var labelColor: Color {
    #if os(macOS)
      Color(nsColor: .labelColor)
    #else
      Color(uiColor: .label)
    #endif
  }

  private var secondaryLabelColor: Color {
    #if os(macOS)
      Color(nsColor: .secondaryLabelColor)
    #else
      Color(uiColor: .secondaryLabel)
    #endif
  }

  @ViewBuilder
  var feedbackSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Leave Feedback", bundle: .module)
        .font(.title3.bold())

      if store.feedbackSubmitted {
        Label {
          Text("Thank you for your feedback!", bundle: .module)
        } icon: {
          Image(systemName: "checkmark.circle.fill")
            .foregroundStyle(Color.green)
        }
      } else {
        TextField(
          String(localized: "Share your thoughts...", bundle: .module),
          text: $store.feedbackText,
          axis: .vertical
        )
        .lineLimit(3...6)
        .textFieldStyle(.roundedBorder)

        if let error = store.feedbackError {
          Text(error)
            .foregroundStyle(Color.red)
            .font(.caption)
        }

        Button {
          send(.submitFeedbackTapped)
        } label: {
          if store.isSubmittingFeedback {
            ProgressView()
          } else {
            Text("Submit", bundle: .module)
          }
        }
        .disabled(
          store.feedbackText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || store.isSubmittingFeedback
        )
        .buttonStyle(.borderedProminent)
      }
    }
    .padding()
    .glassEffectIfAvailable(.regular, in: .rect(cornerRadius: 16))
    .padding()
  }
}

#Preview {
  ScheduleDetailView(
    store: .init(
      initialState: .init(
        proposalId: "preview-id",
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
