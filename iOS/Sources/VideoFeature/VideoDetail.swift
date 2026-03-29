import ComposableArchitecture
import DependencyExtra
import Foundation
import SharedModels
import SwiftUI

@Reducer
public struct VideoDetail: Sendable {

  public enum Tab: String, CaseIterable, Equatable, Sendable {
    case about = "About"
    case transcript = "Transcript"
    #if os(macOS)
      case summary = "Summary"
      case code = "Code"
    #endif
  }

  public struct SeekRequest: Equatable, Sendable {
    public var time: TimeInterval
    public var id: UUID = UUID()
  }

  @ObservableState
  public struct State: Equatable {
    public var session: Session
    public var videoMetadata: VideoMetadata
    public var conferenceYear: ConferenceYear
    public var selectedTab: Tab = .about
    public var currentTime: TimeInterval = 0
    public var seekRequest: SeekRequest?
    public var activeTranscriptEntryId: Int?

    public init(
      session: Session,
      videoMetadata: VideoMetadata,
      conferenceYear: ConferenceYear
    ) {
      self.session = session
      self.videoMetadata = videoMetadata
      self.conferenceYear = conferenceYear
    }
  }

  public enum Action: ViewAction, BindableAction {
    case binding(BindingAction<State>)
    case view(View)

    @CasePathable
    public enum View {
      case tabSelected(Tab)
      case transcriptEntryTapped(TranscriptEntry)
      case chapterTapped(Chapter)
      case resourceTapped(URL)
      case snsTapped(URL)
      case playerTimeUpdated(TimeInterval)
    }
  }

  @Dependency(\.safari) var safari

  public init() {}

  public var body: some ReducerOf<Self> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case .view(.tabSelected(let tab)):
        state.selectedTab = tab
        return .none

      case .view(.transcriptEntryTapped(let entry)):
        state.seekRequest = .init(time: entry.startTime)
        return .none

      case .view(.chapterTapped(let chapter)):
        state.seekRequest = .init(time: chapter.startTime)
        return .none

      case .view(.resourceTapped(let url)):
        return .run { _ in await safari(url) }

      case .view(.snsTapped(let url)):
        return .run { _ in await safari(url) }

      case .view(.playerTimeUpdated(let time)):
        state.currentTime = time
        if let transcript = state.videoMetadata.transcript {
          state.activeTranscriptEntryId = transcript.last(where: { $0.startTime <= time })?.id
        }
        return .none

      case .binding:
        return .none
      }
    }
  }
}
