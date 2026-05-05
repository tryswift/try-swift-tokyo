import Foundation

public struct SponsorMembershipDTO: Codable, Sendable, Equatable {
  public let userID: UUID
  public let organizationID: UUID
  public let role: SponsorMemberRole
  public let invitedByUserID: UUID?
  public let createdAt: Date?

  public init(
    userID: UUID, organizationID: UUID, role: SponsorMemberRole,
    invitedByUserID: UUID?, createdAt: Date?
  ) {
    self.userID = userID
    self.organizationID = organizationID
    self.role = role
    self.invitedByUserID = invitedByUserID
    self.createdAt = createdAt
  }
}
