import Fluent
import SharedModels
import Vapor

final class SponsorInvitation: Model, Content, @unchecked Sendable {
  static let schema = "sponsor_invitations"

  @ID(key: .id) var id: UUID?
  @Parent(key: "organization_id") var organization: SponsorOrganization
  @Field(key: "email") var email: String
  @Field(key: "role") var role: SponsorMemberRole
  @Field(key: "token_hash") var tokenHash: String
  @Field(key: "expires_at") var expiresAt: Date
  @OptionalField(key: "accepted_at") var acceptedAt: Date?
  @Field(key: "invited_by_sponsor_user_id") var invitedByUserID: UUID
  @Timestamp(key: "created_at", on: .create) var createdAt: Date?

  init() {}

  init(
    id: UUID? = nil, organizationID: UUID, email: String,
    role: SponsorMemberRole, tokenHash: String,
    expiresAt: Date, invitedByUserID: UUID
  ) {
    self.id = id
    self.$organization.id = organizationID
    self.email = email.lowercased()
    self.role = role
    self.tokenHash = tokenHash
    self.expiresAt = expiresAt
    self.invitedByUserID = invitedByUserID
  }
}
