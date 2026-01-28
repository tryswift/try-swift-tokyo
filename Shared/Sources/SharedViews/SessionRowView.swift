import SharedModels
import SwiftUI

/// A reusable session row component that displays session information.
/// This view is shared between iOS and Android (via Skip).
/// The SwiftUI syntax is identical on both platforms.
public struct SessionRowView: View {
  let session: Session
  let onTap: (() -> Void)?

  public init(session: Session, onTap: (() -> Void)? = nil) {
    self.session = session
    self.onTap = onTap
  }

  public var body: some View {
    HStack(spacing: 12) {
      speakerAvatars

      VStack(alignment: .leading, spacing: 4) {
        Text(session.title)
          .font(.headline)
          .multilineTextAlignment(.leading)

        if let speakers = session.speakers {
          Text(speakers.map(\.name).joined(separator: ", "))
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }

        if let summary = session.summary {
          Text(summary)
            .font(.caption)
            .foregroundStyle(.tertiary)
            .lineLimit(2)
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)

      if session.description != nil {
        Image(systemName: "chevron.right")
          .foregroundStyle(.secondary)
      }
    }
    .padding()
    .background(Color.secondary.opacity(0.1))
    .clipShape(RoundedRectangle(cornerRadius: 12))
    .contentShape(Rectangle())
    .onTapGesture {
      onTap?()
    }
  }

  @ViewBuilder
  private var speakerAvatars: some View {
    if let speakers = session.speakers {
      VStack(spacing: 4) {
        ForEach(speakers.prefix(2), id: \.name) { speaker in
          SpeakerAvatarView(speaker: speaker, size: 44)
        }
      }
    } else {
      Circle()
        .fill(Color.orange.opacity(0.2))
        .frame(width: 44, height: 44)
        .overlay {
          Image(systemName: "calendar")
            .foregroundStyle(.orange)
        }
    }
  }
}

/// A reusable speaker avatar component.
/// Identical SwiftUI code works on both iOS and Android.
public struct SpeakerAvatarView: View {
  let speaker: Speaker
  let size: CGFloat

  public init(speaker: Speaker, size: CGFloat = 60) {
    self.speaker = speaker
    self.size = size
  }

  public var body: some View {
    Circle()
      .fill(Color.blue.opacity(0.2))
      .frame(width: size, height: size)
      .overlay {
        Text(String(speaker.name.prefix(1)))
          .font(size > 50 ? .title2 : .body)
          .fontWeight(.medium)
          .foregroundStyle(.blue)
      }
  }
}

#Preview {
  VStack(spacing: 16) {
    SessionRowView(
      session: Session(
        title: "Swift Concurrency Deep Dive",
        summary: "Learn about async/await and actors",
        speakers: [
          Speaker(name: "John Doe", imageName: "john", bio: "iOS Developer")
        ],
        place: "Main Hall",
        description: "Full description here",
        requirements: nil
      )
    )

    SessionRowView(
      session: Session(
        title: "Lunch Break",
        summary: nil,
        speakers: nil,
        place: nil,
        description: nil,
        requirements: nil
      )
    )
  }
  .padding()
}
