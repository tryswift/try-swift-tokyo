import Foundation

public struct SponsorUserDTO: Codable, Sendable, Equatable, Identifiable {
  public let id: UUID
  public let email: String
  public let displayName: String?
  public let locale: SponsorPortalLocale
  public let createdAt: Date?

  public init(
    id: UUID, email: String, displayName: String?,
    locale: SponsorPortalLocale, createdAt: Date?
  ) {
    self.id = id
    self.email = email
    self.displayName = displayName
    self.locale = locale
    self.createdAt = createdAt
  }
}
