import SwiftUI
import YouTubePlayerKit
import os

private let logger = Logger(subsystem: "jp.tryswift.tokyo.App", category: "VideoPlayer")

struct VideoPlayerView: View {
  let videoId: String
  var seekRequest: VideoDetail.SeekRequest?
  var onTimeUpdate: (TimeInterval) -> Void

  @State private var player: YouTubePlayer

  init(
    videoId: String,
    seekRequest: VideoDetail.SeekRequest? = nil,
    onTimeUpdate: @escaping (TimeInterval) -> Void
  ) {
    self.videoId = videoId
    self.seekRequest = seekRequest
    self.onTimeUpdate = onTimeUpdate
    self._player = State(
      initialValue: YouTubePlayer(
        source: .video(id: videoId),
        parameters: .init(
          autoPlay: false,
          showControls: true,
        ),
        configuration: .init(
          allowsPictureInPictureMediaPlayback: true
        )
      ))
  }

  var body: some View {
    YouTubePlayerView(player) { state in
      switch state {
      case .idle, .ready:
        EmptyView()
      case .error(let error):
        ContentUnavailableView(
          "Video Unavailable",
          systemImage: "play.slash",
          description: Text("This video could not be loaded.")
        )
        .onAppear {
          logger.error(
            "YouTube player error for video \(videoId, privacy: .public): \(String(describing: error), privacy: .public)"
          )
        }
      }
    }
    .aspectRatio(16.0 / 9.0, contentMode: .fit)
    .clipShape(RoundedRectangle(cornerRadius: 12))
    .onChange(of: seekRequest) { _, newValue in
      if let request = newValue {
        Task {
          let measurement = Measurement<UnitDuration>(value: request.time, unit: .seconds)
          try? await player.seek(to: measurement, allowSeekAhead: true)
          try? await player.play()
        }
      }
    }
    .task {
      while !Task.isCancelled {
        try? await Task.sleep(for: .milliseconds(500))
        guard !Task.isCancelled else { break }
        if let time = try? await player.getCurrentTime() {
          onTimeUpdate(time.converted(to: .seconds).value)
        }
      }
    }
  }
}
