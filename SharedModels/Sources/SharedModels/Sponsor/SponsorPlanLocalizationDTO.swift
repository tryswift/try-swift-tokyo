import Foundation

public struct SponsorPlanLocalizationDTO: Codable, Sendable, Equatable {
  public let locale: SponsorPortalLocale
  public let name: String
  public let summary: String
  public let benefits: [String]

  public init(locale: SponsorPortalLocale, name: String, summary: String, benefits: [String]) {
    self.locale = locale
    self.name = name
    self.summary = summary
    self.benefits = benefits
  }
}
