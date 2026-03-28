import Fluent
import Vapor

/// Favorite model for tracking user's favorite talks (identified by device ID)
final class Favorite: Model, Content, @unchecked Sendable {
  static let schema = "favorites"

  @ID(key: .id)
  var id: UUID?

  /// Reference to the proposal this favorite is for
  @Parent(key: "proposal_id")
  var proposal: Proposal

  /// Device identifier (anonymous user identity)
  @Field(key: "device_id")
  var deviceID: String

  /// Timestamps
  @Timestamp(key: "created_at", on: .create)
  var createdAt: Date?

  init() {}

  init(
    id: UUID? = nil,
    proposalID: UUID,
    deviceID: String
  ) {
    self.id = id
    self.$proposal.id = proposalID
    self.deviceID = deviceID
  }
}
