import Foundation

public struct SponsorInquiryDTO: Codable, Sendable, Equatable, Identifiable {
  public let id: UUID
  public let conferenceID: UUID
  public let companyName: String
  public let contactName: String
  public let email: String
  public let desiredPlanSlug: String?
  public let message: String
  public let locale: SponsorPortalLocale
  public let createdAt: Date?

  public init(
    id: UUID, conferenceID: UUID, companyName: String, contactName: String,
    email: String, desiredPlanSlug: String?, message: String,
    locale: SponsorPortalLocale, createdAt: Date?
  ) {
    self.id = id
    self.conferenceID = conferenceID
    self.companyName = companyName
    self.contactName = contactName
    self.email = email
    self.desiredPlanSlug = desiredPlanSlug
    self.message = message
    self.locale = locale
    self.createdAt = createdAt
  }
}
