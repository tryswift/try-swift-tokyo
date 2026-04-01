import DependencyExtra
import SharedModels
import SwiftUI

struct AboutTabView: View {
  let session: Session
  let videoMetadata: VideoMetadata
  let conferenceYear: ConferenceYear
  var speakerImageBundle: Bundle = .main
  var relatedSessions: [RelatedSession] = []
  var onChapterTapped: (Chapter) -> Void
  var onResourceTapped: (URL) -> Void
  var onSnsTapped: (URL) -> Void
  var onRelatedSessionTapped: ((RelatedSession) -> Void)?

  var body: some View {
    VStack(alignment: .leading, spacing: 24) {
      descriptionSection
      speakersSection
      chaptersSection
      resourcesSection
      relatedSessionsSection
    }
    .padding(.horizontal)
    .padding(.bottom)
  }

  // MARK: - Conference Header

  // MARK: - Description

  @ViewBuilder
  private var descriptionSection: some View {
    if let description = session.description {
      VStack(alignment: .leading, spacing: 8) {
        VStack(alignment: .leading, spacing: 4) {
          Text(session.title)
            .font(.title2.bold())
          Text("try! Swift Tokyo \(String(conferenceYear.rawValue))")
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
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

  // MARK: - Related Sessions

  @ViewBuilder
  private var relatedSessionsSection: some View {
    if !relatedSessions.isEmpty {
      VStack(alignment: .leading, spacing: 12) {
        Text("Related Sessions", bundle: .module)
          .font(.headline)
          .foregroundStyle(.secondary)

        ForEach(relatedSessions) { related in
          Button {
            onRelatedSessionTapped?(related)
          } label: {
            relatedSessionRow(related)
              .padding()
          }
          .buttonStyle(.plain)
          .glassEffectIfAvailable()
        }
      }
    }
  }

  @ViewBuilder
  private func relatedSessionRow(_ related: RelatedSession) -> some View {
    HStack(spacing: 8) {
      if let imageName = related.speakerImageName {
        Image(imageName, bundle: speakerImageBundle)
          .resizable()
          .aspectRatio(contentMode: .fit)
          .clipShape(Circle())
          .frame(width: 44)
          .accessibilityIgnoresInvertColors()
      }
      VStack(alignment: .leading, spacing: 2) {
        Text(related.session.title)
          .font(.body)
          .multilineTextAlignment(.leading)
        if let speakerName = related.speakerName {
          Text(speakerName)
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        Text(String(related.year.rawValue))
          .font(.caption2)
          .foregroundStyle(.tertiary)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .accessibilityElement(children: .combine)
    }
  }

  // MARK: - Helpers

  private func formattedTime(_ seconds: TimeInterval) -> String {
    let minutes = Int(seconds) / 60
    let secs = Int(seconds) % 60
    return String(format: "%d:%02d", minutes, secs)
  }
}
