import Fluent
import SharedModels
import Vapor

final class SponsorPlanLocalization: Model, Content, @unchecked Sendable {
  static let schema = "sponsor_plan_localizations"

  @ID(key: .id) var id: UUID?
  @Parent(key: "plan_id") var plan: SponsorPlan
  @Field(key: "locale") var locale: SponsorPortalLocale
  @Field(key: "name") var name: String
  @Field(key: "summary") var summary: String
  @Field(key: "benefits") var benefits: [String]

  init() {}

  init(
    id: UUID? = nil, planID: UUID, locale: SponsorPortalLocale,
    name: String, summary: String, benefits: [String]
  ) {
    self.id = id
    self.$plan.id = planID
    self.locale = locale
    self.name = name
    self.summary = summary
    self.benefits = benefits
  }

  func toDTO() -> SponsorPlanLocalizationDTO {
    SponsorPlanLocalizationDTO(locale: locale, name: name, summary: summary, benefits: benefits)
  }
}
