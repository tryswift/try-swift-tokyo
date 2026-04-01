import ComposableArchitecture
import SharedModels
import SwiftUI

@ViewAction(for: VideoDetail.self)
public struct VideoDetailView: View {

  @Bindable public var store: StoreOf<VideoDetail>
  let speakerImageBundle: Bundle

  public init(store: StoreOf<VideoDetail>, speakerImageBundle: Bundle = .main) {
    self.store = store
    self.speakerImageBundle = speakerImageBundle
  }

  public var body: some View {
    ScrollView {
      VStack(spacing: 0) {
        // Video Player
        VideoPlayerView(
          videoId: store.videoMetadata.youtubeVideoId,
          seekRequest: store.seekRequest,
          onTimeUpdate: { time in
            send(.playerTimeUpdated(time))
          }
        )
        .id(store.videoMetadata.youtubeVideoId)

        // Tab Picker
        Picker("Content", selection: $store.selectedTab.sending(\.view.tabSelected)) {
          Text("About").tag(VideoDetail.Tab.about)
          if store.videoMetadata.transcript != nil {
            Text("Transcript").tag(VideoDetail.Tab.transcript)
          }
          #if os(macOS)
            if store.videoMetadata.summary != nil {
              Text("Summary").tag(VideoDetail.Tab.summary)
            }
            if store.videoMetadata.codeResources != nil {
              Text("Code").tag(VideoDetail.Tab.code)
            }
          #endif
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .accessibilityLabel(Text("Content", bundle: .module))
        .padding()

        // Tab Content
        tabContent
      }
      .frame(maxWidth: 700)
    }
//    .navigationTitle(store.session.title)
    #if !os(macOS)
      .navigationBarTitleDisplayMode(.inline)
    #endif
  }

  @ViewBuilder
  private var tabContent: some View {
    switch store.selectedTab {
    case .about:
      AboutTabView(
        session: store.session,
        videoMetadata: store.videoMetadata,
        conferenceYear: store.conferenceYear,
        speakerImageBundle: speakerImageBundle,
        onChapterTapped: { chapter in
          send(.chapterTapped(chapter))
        },
        onResourceTapped: { url in
          send(.resourceTapped(url))
        },
        onSnsTapped: { url in
          send(.snsTapped(url))
        }
      )

    case .transcript:
      if let transcript = store.videoMetadata.transcript {
        TranscriptView(
          transcript: transcript,
          activeEntryId: store.activeTranscriptEntryId,
          onEntryTapped: { entry in
            send(.transcriptEntryTapped(entry))
          }
        )
      }

    #if os(macOS)
      case .summary:
        if let summary = store.videoMetadata.summary {
          SummaryTabView(summary: summary)
        }

      case .code:
        if let codeResources = store.videoMetadata.codeResources {
          CodeTabView(
            codeResources: codeResources,
            onResourceTapped: { url in
              send(.resourceTapped(url))
            }
          )
        }
    #endif
    }
  }
}

#Preview {
  NavigationStack {
    VideoDetailView(
      store: .init(
        initialState: .init(
          session: Session(
            title: "Native macOS application, or the world of AppKit",
            speakers: [
              Speaker(
                name: "1024jp",
                imageName: "1024jp",
                bio: "macOS developer/designer",
                links: []
              )
            ],
            place: "Main Hall",
            description:
              "Swift is the language which we cannot build native application in the iOS or macOS world without.",
            requirements: nil
          ),
          videoMetadata: VideoMetadata(
            sessionTitle: "Native macOS application, or the world of AppKit",
            youtubeVideoId: "dQw4w9WgXcQ",
            chapters: [
              Chapter(title: "Introduction", startTime: 0),
              Chapter(title: "AppKit Fundamentals", startTime: 120),
            ],
            transcript: [
              TranscriptEntry(
                id: 1, startTime: 0, endTime: 5,
                text: "Hello everyone, thank you for coming."),
              TranscriptEntry(
                id: 2, startTime: 5, endTime: 12,
                text: "Today I'd like to talk about native macOS applications."),
            ],
            resources: [
              VideoResource(
                title: "Slide Deck", url: URL(string: "https://example.com")!)
            ]
          ),
          conferenceYear: .year2019
        ),
        reducer: {
          VideoDetail()
        }
      )
    )
  }
}
