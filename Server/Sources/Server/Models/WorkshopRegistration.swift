import Fluent
import Vapor

/// Workshop registration model linking accepted workshop proposals to lottery settings
final class WorkshopRegistration: Model, Content, @unchecked Sendable {
  static let schema = "workshop_registrations"

  @ID(key: .id)
  var id: UUID?

  /// Reference to the accepted workshop proposal
  @Parent(key: "proposal_id")
  var proposal: Proposal

  /// Maximum number of attendees
  @Field(key: "capacity")
  var capacity: Int

  /// Luma event ID (set after organizer creates the Luma event post-lottery)
  @OptionalField(key: "luma_event_id")
  var lumaEventID: String?

  @Timestamp(key: "created_at", on: .create)
  var createdAt: Date?

  @Timestamp(key: "updated_at", on: .update)
  var updatedAt: Date?

  init() {}

  init(
    id: UUID? = nil,
    proposalID: UUID,
    capacity: Int,
    lumaEventID: String? = nil
  ) {
    self.id = id
    self.$proposal.id = proposalID
    self.capacity = capacity
    self.lumaEventID = lumaEventID
  }
}
