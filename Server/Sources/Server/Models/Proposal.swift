import Fluent
import SharedModels
import Vapor

/// Proposal model for CfP submissions
final class Proposal: Model, Content, @unchecked Sendable {
  static let schema = "proposals"

  @ID(key: .id)
  var id: UUID?

  /// Reference to the conference this proposal is for
  @Parent(key: "conference_id")
  var conference: Conference

  /// Proposal title
  @Field(key: "title")
  var title: String

  /// Proposal abstract/description (public summary)
  @Field(key: "abstract")
  var abstract: String

  /// Detailed talk description (for reviewers)
  @Field(key: "talk_detail")
  var talkDetail: String

  /// Talk duration (20min or LT)
  @Field(key: "talk_duration")
  var talkDuration: TalkDuration

  /// Speaker name at time of submission
  @Field(key: "speaker_name")
  var speakerName: String

  /// Speaker email at time of submission
  @Field(key: "speaker_email")
  var speakerEmail: String

  /// Speaker bio
  @Field(key: "bio")
  var bio: String

  /// Speaker icon/avatar URL
  @OptionalField(key: "icon_url")
  var iconURL: String?

  /// Additional notes for organizers
  @OptionalField(key: "notes")
  var notes: String?

  /// PaperCall ID (if imported from PaperCall.io)
  @OptionalField(key: "papercall_id")
  var paperCallID: String?

  /// PaperCall Speaker Username (for reference when imported)
  @OptionalField(key: "papercall_username")
  var paperCallUsername: String?

  /// GitHub username entered by the speaker at submission time (may differ from the
  /// authenticated User username or PaperCall username)
  @OptionalField(key: "github_username")
  var githubUsername: String?

  /// Proposal review status
  @Field(key: "status")
  var status: ProposalStatus

  /// Reference to the speaker who submitted the proposal
  @Parent(key: "speaker_id")
  var speaker: User

  /// Timestamps
  @Timestamp(key: "created_at", on: .create)
  var createdAt: Date?

  @Timestamp(key: "updated_at", on: .update)
  var updatedAt: Date?

  init() {}

  init(
    id: UUID? = nil,
    conferenceID: UUID,
    title: String,
    abstract: String,
    talkDetail: String,
    talkDuration: TalkDuration,
    speakerName: String,
    speakerEmail: String,
    bio: String,
    iconURL: String? = nil,
    notes: String? = nil,
    speakerID: UUID,
    status: ProposalStatus = .submitted,
    githubUsername: String? = nil
  ) {
    self.id = id
    self.$conference.id = conferenceID
    self.title = title
    self.abstract = abstract
    self.talkDetail = talkDetail
    self.talkDuration = talkDuration
    self.speakerName = speakerName
    self.speakerEmail = speakerEmail
    self.bio = bio
    self.iconURL = iconURL
    self.notes = notes
    self.$speaker.id = speakerID
    self.status = status
    self.githubUsername = githubUsername
  }

  /// Convert to DTO for API responses
  func toDTO(speakerUsername: String, conference: Conference) throws -> ProposalDTO {
    guard let id = id else {
      throw Abort(.internalServerError, reason: "Proposal ID is missing")
    }
    guard let conferenceId = conference.id else {
      throw Abort(.internalServerError, reason: "Conference ID is missing")
    }
    return ProposalDTO(
      id: id,
      conferenceId: conferenceId,
      conferencePath: conference.path,
      conferenceDisplayName: conference.displayName,
      title: title,
      abstract: abstract,
      talkDetail: talkDetail,
      talkDuration: talkDuration,
      speakerName: speakerName,
      speakerEmail: speakerEmail,
      bio: bio,
      iconURL: iconURL,
      notes: notes,
      speakerID: $speaker.id,
      speakerUsername: speakerUsername,
      status: status,
      createdAt: createdAt,
      updatedAt: updatedAt,
      githubUsername: githubUsername
    )
  }
}
