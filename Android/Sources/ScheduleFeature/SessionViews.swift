import SharedModels
import SwiftUI

/// A reusable session row component for Android.
public struct SessionRowView: View {
  let session: Session

  public init(session: Session) {
    self.session = session
  }

  public var body: some View {
    HStack(spacing: 12) {
      speakerAvatars

      VStack(alignment: HorizontalAlignment.leading, spacing: 4) {
        Text(session.title)
          .font(Font.headline)
          .multilineTextAlignment(TextAlignment.leading)

        if let speakers = session.speakers {
          Text(speakerNames(speakers))
            .font(Font.subheadline)
            .foregroundStyle(Color.secondary)
        }

        if let summary = session.summary {
          Text(summary)
            .font(Font.caption)
            .foregroundStyle(Color.gray)
            .lineLimit(2)
        }
      }
      .frame(maxWidth: CGFloat.infinity, alignment: Alignment.leading)

      if session.description != nil {
        Image(systemName: "chevron.right")
          .foregroundStyle(Color.secondary)
      }
    }
    .padding()
    .background(Color.secondary.opacity(0.1))
    .clipShape(RoundedRectangle(cornerRadius: 12))
  }

  // Helper function to avoid Kotlin type inference issues with map
  private func speakerNames(_ speakers: [Speaker]) -> String {
    var names: [String] = []
    for speaker in speakers {
      names.append(speaker.name)
    }
    return names.joined(separator: ", ")
  }

  @ViewBuilder
  private var speakerAvatars: some View {
    if let speakers = session.speakers {
      VStack(spacing: 4) {
        ForEach(Array(speakers.prefix(2)), id: \.name) { speaker in
          SpeakerAvatarView(speaker: speaker, size: 44)
        }
      }
    } else {
      Circle()
        .fill(Color.orange.opacity(0.2))
        .frame(width: 44, height: 44)
        .overlay {
          Image(systemName: "calendar")
            .foregroundStyle(Color.orange)
        }
    }
  }
}

/// A reusable speaker avatar component for Android.
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
        Text(avatarInitial)
          .font(avatarFont)
          .fontWeight(Font.Weight.medium)
          .foregroundStyle(Color.blue)
      }
  }

  private var avatarInitial: String {
    String(speaker.name.prefix(1))
  }

  private var avatarFont: Font {
    size > 50 ? Font.title2 : Font.body
  }
}

/// A detailed view for displaying session information on Android.
public struct SessionDetailView: View {
  let session: Session

  public init(session: Session) {
    self.session = session
  }

  public var body: some View {
    ScrollView {
      VStack(alignment: HorizontalAlignment.leading, spacing: 24) {
        headerSection

        if let speakers = session.speakers, !speakers.isEmpty {
          speakersSection(speakers: speakers)
        }

        if let description = session.description {
          descriptionSection(description: description)
        }

        if let requirements = session.requirements {
          requirementsSection(requirements: requirements)
        }
      }
      .padding()
    }
  }

  private var headerSection: some View {
    VStack(alignment: HorizontalAlignment.leading, spacing: 8) {
      Text(session.title)
        .font(Font.largeTitle.bold())

      if let place = session.place {
        Label(place, systemImage: "mappin.circle")
          .font(Font.subheadline)
          .foregroundStyle(Color.secondary)
      }
    }
  }

  private func speakersSection(speakers: [Speaker]) -> some View {
    VStack(alignment: HorizontalAlignment.leading, spacing: 12) {
      Text("Speakers")
        .font(Font.title3.bold())

      ForEach(speakers, id: \.name) { speaker in
        HStack(spacing: 12) {
          SpeakerAvatarView(speaker: speaker, size: 56)

          VStack(alignment: HorizontalAlignment.leading, spacing: 4) {
            Text(speaker.name)
              .font(Font.headline)

            if let bio = speaker.bio {
              Text(bio)
                .font(Font.subheadline)
                .foregroundStyle(Color.secondary)
                .lineLimit(3)
            }
          }
        }
      }
    }
  }

  private func descriptionSection(description: String) -> some View {
    VStack(alignment: HorizontalAlignment.leading, spacing: 8) {
      Text("Description")
        .font(Font.title3.bold())

      Text(description)
        .font(Font.body)
    }
  }

  private func requirementsSection(requirements: String) -> some View {
    VStack(alignment: HorizontalAlignment.leading, spacing: 8) {
      Text("Requirements")
        .font(Font.title3.bold())

      Text(requirements)
        .font(Font.body)
        .padding()
        .frame(maxWidth: CGFloat.infinity, alignment: Alignment.leading)
        .background(Color.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
  }
}
