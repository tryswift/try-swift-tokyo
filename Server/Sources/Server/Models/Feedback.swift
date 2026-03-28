import Fluent
import Vapor

/// Feedback model for anonymous talk feedback from attendees
final class Feedback: Model, Content, @unchecked Sendable {
  static let schema = "feedbacks"

  @ID(key: .id)
  var id: UUID?

  /// Reference to the proposal this feedback is for
  @Parent(key: "proposal_id")
  var proposal: Proposal

  /// Feedback comment text
  @Field(key: "comment")
  var comment: String

  /// Device identifier for rate limiting (anonymous)
  @OptionalField(key: "device_id")
  var deviceID: String?

  /// Timestamps
  @Timestamp(key: "created_at", on: .create)
  var createdAt: Date?

  init() {}

  init(
    id: UUID? = nil,
    proposalID: UUID,
    comment: String,
    deviceID: String? = nil
  ) {
    self.id = id
    self.$proposal.id = proposalID
    self.comment = comment
    self.deviceID = deviceID
  }
}
