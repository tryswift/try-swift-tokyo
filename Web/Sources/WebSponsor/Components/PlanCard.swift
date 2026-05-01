import Elementary
import SharedModels

public struct PlanCard: HTML {
  public let locale: SponsorPortalLocale
  public let plan: SponsorPlanDTO

  public init(locale: SponsorPortalLocale, plan: SponsorPlanDTO) {
    self.locale = locale
    self.plan = plan
  }

  public var body: some HTML {
    let l = plan.localized(for: locale)
    article(.class("plan-card")) {
      h2 { l?.name ?? plan.slug }
      p { "¥\(plan.priceJPY.formatted())" }
      if let summary = l?.summary { p { summary } }
      if let benefits = l?.benefits, !benefits.isEmpty {
        ul {
          for b in benefits { li { b } }
        }
      }
      a(.href("/applications/new?plan=\(plan.slug)"), .class("apply-button")) {
        locale == .ja ? "このプランで申し込む" : "Apply for this plan"
      }
    }
  }
}
