import Fluent
import SharedModels
import Vapor

final class SponsorOrganization: Model, Content, @unchecked Sendable {
  static let schema = "sponsor_organizations"

  @ID(key: .id) var id: UUID?
  @Field(key: "legal_name") var legalName: String
  @Field(key: "display_name") var displayName: String
  @OptionalField(key: "country") var country: String?
  @OptionalField(key: "billing_address") var billingAddress: String?
  @OptionalField(key: "website_url") var websiteURL: String?
  @Field(key: "status") var status: SponsorOrganizationStatus
  @Timestamp(key: "created_at", on: .create) var createdAt: Date?
  @Timestamp(key: "updated_at", on: .update) var updatedAt: Date?

  @Children(for: \.$organization) var memberships: [SponsorMembership]

  init() {}

  init(
    id: UUID? = nil, legalName: String, displayName: String,
    country: String? = nil, billingAddress: String? = nil,
    websiteURL: String? = nil, status: SponsorOrganizationStatus = .active
  ) {
    self.id = id
    self.legalName = legalName
    self.displayName = displayName
    self.country = country
    self.billingAddress = billingAddress
    self.websiteURL = websiteURL
    self.status = status
  }

  func toDTO() throws -> SponsorOrganizationDTO {
    guard let id else {
      throw Abort(.internalServerError, reason: "SponsorOrganization missing id")
    }
    return SponsorOrganizationDTO(
      id: id, legalName: legalName, displayName: displayName,
      country: country, billingAddress: billingAddress,
      websiteURL: websiteURL, status: status,
      createdAt: createdAt, updatedAt: updatedAt
    )
  }
}
