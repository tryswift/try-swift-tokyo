import SharedModels
import SwiftUI

/// A detailed view for displaying session information.
/// This SwiftUI code is identical on iOS and Android (via Skip).
public struct SessionDetailView: View {
  let session: Session

  public init(session: Session) {
    self.session = session
  }

  public var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 24) {
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
    VStack(alignment: .leading, spacing: 8) {
      Text(session.title)
        .font(.largeTitle.bold())

      if let place = session.place {
        Label(place, systemImage: "mappin.circle")
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }
    }
  }

  private func speakersSection(speakers: [Speaker]) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Speakers")
        .font(.title3.bold())

      ForEach(speakers, id: \.name) { speaker in
        HStack(spacing: 12) {
          SpeakerAvatarView(speaker: speaker, size: 56)

          VStack(alignment: .leading, spacing: 4) {
            Text(speaker.name)
              .font(.headline)

            if let bio = speaker.bio {
              Text(bio)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(3)
            }
          }
        }
      }
    }
  }

  private func descriptionSection(description: String) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Description")
        .font(.title3.bold())

      Text(description)
        .font(.body)
    }
  }

  private func requirementsSection(requirements: String) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Requirements")
        .font(.title3.bold())

      Text(requirements)
        .font(.body)
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
  }
}

#Preview {
  NavigationStack {
    SessionDetailView(
      session: Session(
        title: "Building Cross-Platform Apps with Skip",
        summary: "Learn how to share Swift code between iOS and Android",
        speakers: [
          Speaker(
            name: "Jane Smith",
            imageName: "jane",
            bio: "Senior iOS Developer with 10 years of experience"
          )
        ],
        place: "Main Hall",
        description:
          "In this session, we'll explore how Skip enables you to write SwiftUI code that runs on both iOS and Android. You'll learn about the architecture, limitations, and best practices.",
        requirements: "Basic knowledge of SwiftUI and Swift"
      )
    )
    .navigationTitle("Session")
    .navigationBarTitleDisplayMode(.inline)
  }
}
