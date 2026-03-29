import DependencyExtra
import SharedModels
import SwiftUI

struct AboutTabView: View {
  let session: Session
  let videoMetadata: VideoMetadata
  let conferenceYear: ConferenceYear
  var speakerImageBundle: Bundle = .main
  var onChapterTapped: (Chapter) -> Void
  var onResourceTapped: (URL) -> Void
  var onSnsTapped: (URL) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 24) {
      conferenceHeader
      descriptionSection
      speakersSection
      chaptersSection
      resourcesSection
    }
    .padding(.horizontal)
    .padding(.bottom)
  }

  // MARK: - Conference Header

  @ViewBuilder
  private var conferenceHeader: some View {
    Text("try! Swift Tokyo \(String(conferenceYear.rawValue))")
      .font(.subheadline)
      .foregroundStyle(.secondary)
  }

  // MARK: - Description

  @ViewBuilder
  private var descriptionSection: some View {
    if let description = session.description {
      VStack(alignment: .leading, spacing: 8) {
        Text(session.title)
          .font(.title2.bold())
        Text(description)
          .font(.body)
      }
    }
  }

  // MARK: - Speakers

  @ViewBuilder
  private var speakersSection: some View {
    if let speakers = session.speakers, !speakers.isEmpty {
      VStack(alignment: .leading, spacing: 12) {
        Text("Speaker")
          .font(.headline)
          .foregroundStyle(.secondary)

        ForEach(speakers, id: \.self) { speaker in
          VStack(spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
              Image(speaker.imageName, bundle: speakerImageBundle)
                .resizable()
                .aspectRatio(1.0, contentMode: .fit)
                .frame(width: 56)
                .clipShape(Circle())
                .accessibilityIgnoresInvertColors()

              VStack(alignment: .leading, spacing: 4) {
                Text(speaker.name)
                  .font(.headline)
                if let jobTitle = speaker.jobTitle {
                  Text(jobTitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                if let links = speaker.links {
                  HStack {
                    ForEach(links, id: \.self) { link in
                      Button(link.name) {
                        onSnsTapped(link.url)
                      }
                      .font(.subheadline)
                      .accessibilityAddTraits(.isLink)
                    }
                  }
                }
              }
            }

            if let bio = speaker.bio {
              Text(bio)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
          }
          .padding()
          .frame(maxWidth: .infinity, alignment: .leading)
          .glassEffectIfAvailable()
        }
      }
    }
  }

  // MARK: - Chapters

  @ViewBuilder
  private var chaptersSection: some View {
    if let chapters = videoMetadata.chapters, !chapters.isEmpty {
      VStack(alignment: .leading, spacing: 8) {
        Text("Chapters")
          .font(.headline)
          .foregroundStyle(.secondary)

        ForEach(Array(chapters.enumerated()), id: \.offset) { _, chapter in
          Button {
            onChapterTapped(chapter)
          } label: {
            HStack {
              Text(formattedTime(chapter.startTime))
                .font(.subheadline.monospaced())
                .foregroundStyle(Color.accentColor)
                .frame(width: 60, alignment: .leading)
              Text(chapter.title)
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 4)
          }
          .buttonStyle(.plain)
        }
      }
    }
  }

  // MARK: - Resources

  @ViewBuilder
  private var resourcesSection: some View {
    if let resources = videoMetadata.resources, !resources.isEmpty {
      VStack(alignment: .leading, spacing: 8) {
        Text("Resources")
          .font(.headline)
          .foregroundStyle(.secondary)

        ForEach(resources, id: \.self) { resource in
          Button {
            onResourceTapped(resource.url)
          } label: {
            Label(resource.title, systemImage: "link")
              .font(.subheadline)
          }
          .buttonStyle(.plain)
          .foregroundStyle(Color.accentColor)
        }
      }
    }
  }

  // MARK: - Helpers

  private func formattedTime(_ seconds: TimeInterval) -> String {
    let minutes = Int(seconds) / 60
    let secs = Int(seconds) % 60
    return String(format: "%d:%02d", minutes, secs)
  }
}
