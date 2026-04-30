import Foundation

public struct SponsorOrganizationDTO: Codable, Sendable, Equatable, Identifiable {
  public let id: UUID
  public let legalName: String
  public let displayName: String
  public let country: String?
  public let billingAddress: String?
  public let websiteURL: String?
  public let status: SponsorOrganizationStatus
  public let createdAt: Date?
  public let updatedAt: Date?

  public init(
    id: UUID, legalName: String, displayName: String, country: String?,
    billingAddress: String?, websiteURL: String?,
    status: SponsorOrganizationStatus, createdAt: Date?, updatedAt: Date?
  ) {
    self.id = id
    self.legalName = legalName
    self.displayName = displayName
    self.country = country
    self.billingAddress = billingAddress
    self.websiteURL = websiteURL
    self.status = status
    self.createdAt = createdAt
    self.updatedAt = updatedAt
  }
}
