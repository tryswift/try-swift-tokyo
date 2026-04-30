import Fluent
import SharedModels
import Vapor

final class SponsorMembership: Model, Content, @unchecked Sendable {
  static let schema = "sponsor_memberships"

  @ID(key: .id) var id: UUID?

  @Parent(key: "organization_id") var organization: SponsorOrganization
  @Parent(key: "sponsor_user_id") var user: SponsorUser

  @Field(key: "role") var role: SponsorMemberRole
  @OptionalField(key: "invited_by_sponsor_user_id") var invitedByUserID: UUID?

  @Timestamp(key: "created_at", on: .create) var createdAt: Date?

  init() {}

  init(
    id: UUID? = nil, organizationID: UUID, userID: UUID,
    role: SponsorMemberRole, invitedByUserID: UUID? = nil
  ) {
    self.id = id
    self.$organization.id = organizationID
    self.$user.id = userID
    self.role = role
    self.invitedByUserID = invitedByUserID
  }

  func toDTO() -> SponsorMembershipDTO {
    SponsorMembershipDTO(
      userID: $user.id, organizationID: $organization.id,
      role: role, invitedByUserID: invitedByUserID, createdAt: createdAt
    )
  }
}
