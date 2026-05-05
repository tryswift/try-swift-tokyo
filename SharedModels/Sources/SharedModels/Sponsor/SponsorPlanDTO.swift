import Foundation

public struct SponsorPlanDTO: Codable, Sendable, Equatable, Identifiable {
  public let id: UUID
  public let conferenceID: UUID
  public let slug: String
  public let sortOrder: Int
  public let priceJPY: Int
  public let capacity: Int?
  public let deadlineAt: Date?
  public let isActive: Bool
  public let localizations: [SponsorPlanLocalizationDTO]

  public init(
    id: UUID, conferenceID: UUID, slug: String, sortOrder: Int,
    priceJPY: Int, capacity: Int?, deadlineAt: Date?, isActive: Bool,
    localizations: [SponsorPlanLocalizationDTO]
  ) {
    self.id = id
    self.conferenceID = conferenceID
    self.slug = slug
    self.sortOrder = sortOrder
    self.priceJPY = priceJPY
    self.capacity = capacity
    self.deadlineAt = deadlineAt
    self.isActive = isActive
    self.localizations = localizations
  }

  public func localized(for locale: SponsorPortalLocale) -> SponsorPlanLocalizationDTO? {
    localizations.first(where: { $0.locale == locale })
      ?? localizations.first(where: { $0.locale == .default })
  }
}
