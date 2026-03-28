import SharedModels
import SwiftUI

/// A reusable session row component for Android.
public struct SessionRowView: View {
  let session: Session
  let isFavorite: Bool
  let favoriteCount: Int
  let onToggleFavorite: (() -> Void)?

  public init(
    session: Session, isFavorite: Bool = false, favoriteCount: Int = 0,
    onToggleFavorite: (() -> Void)? = nil
  ) {
    self.session = session
    self.isFavorite = isFavorite
    self.favoriteCount = favoriteCount
    self.onToggleFavorite = onToggleFavorite
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

      if session.proposalId != nil, let onToggle = onToggleFavorite {
        Button {
          onToggle()
        } label: {
          HStack(spacing: 2) {
            Image(systemName: isFavorite ? "heart.fill" : "heart")
              .foregroundStyle(isFavorite ? Color.red : Color.secondary)
            if favoriteCount > 0 {
              Text(String(favoriteCount))
                .font(Font.caption2)
                .foregroundStyle(isFavorite ? Color.red : Color.secondary)
            }
          }
        }
        .buttonStyle(.plain)
      }

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
  @ObservedObject private var viewModelRef: ViewModelRef

  @Environment(\.openURL) private var openURL

  public init(session: Session, viewModel: ScheduleViewModel) {
    self.session = session
    self.viewModelRef = ViewModelRef(viewModel: viewModel)
  }

  private var viewModel: ScheduleViewModel {
    viewModelRef.viewModel
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

        if session.proposalId != nil {
          feedbackSection
        }
      }
      .padding()
    }
    .toolbar {
      if let proposalId = session.proposalId {
        ToolbarItem(placement: ToolbarItemPlacement.topBarTrailing) {
          Button {
            viewModel.toggleFavorite(proposalId: proposalId)
          } label: {
            HStack(spacing: 2) {
              Image(
                systemName: viewModel.isFavorite(proposalId: session.proposalId)
                  ? "heart.fill" : "heart"
              )
              .foregroundStyle(
                viewModel.isFavorite(proposalId: session.proposalId) ? Color.red : Color.secondary)
              let count = viewModel.favoriteCount(proposalId: session.proposalId)
              if count > 0 {
                Text(String(count))
                  .font(Font.caption2)
                  .foregroundStyle(
                    viewModel.isFavorite(proposalId: session.proposalId)
                      ? Color.red : Color.secondary)
              }
            }
          }
        }
      }
    }
    .onDisappear {
      viewModel.resetFeedbackState()
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

            if let links = speaker.links, !links.isEmpty {
              HStack(spacing: 8) {
                ForEach(links, id: \.url) { link in
                  Button {
                    openURL(link.url)
                  } label: {
                    Text(link.name)
                      .font(Font.caption)
                  }
                  .buttonStyle(.bordered)
                }
              }
            }

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

  @ViewBuilder
  private var feedbackSection: some View {
    VStack(alignment: HorizontalAlignment.leading, spacing: 12) {
      Text("Leave Feedback")
        .font(Font.title3.bold())

      if viewModel.feedbackSubmitted {
        Label("Thank you for your feedback!", systemImage: "checkmark.circle.fill")
          .foregroundStyle(Color.green)
      } else {
        TextField(
          "Share your thoughts...",
          text: Binding(
            get: { viewModel.feedbackText },
            set: { viewModel.feedbackText = $0 }
          ), axis: .vertical
        )
        .lineLimit(3...6)
        .textFieldStyle(.roundedBorder)

        if let error = viewModel.feedbackError {
          Text(error)
            .foregroundStyle(Color.red)
            .font(Font.caption)
        }

        Button {
          if let proposalId = session.proposalId {
            viewModel.submitFeedback(proposalId: proposalId)
          }
        } label: {
          if viewModel.isSubmittingFeedback {
            ProgressView()
          } else {
            Text("Submit")
          }
        }
        .disabled(
          viewModel.feedbackText.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).isEmpty
            || viewModel.isSubmittingFeedback
        )
        .buttonStyle(.borderedProminent)
      }
    }
    .padding()
    .background(Color.secondary.opacity(0.1))
    .clipShape(RoundedRectangle(cornerRadius: 12))
  }
}

/// Helper class to pass ScheduleViewModel to SessionDetailView
/// Skip's @Observable doesn't work with @Binding directly in all cases
private class ViewModelRef: ObservableObject {
  let viewModel: ScheduleViewModel
  init(viewModel: ScheduleViewModel) {
    self.viewModel = viewModel
  }
}
