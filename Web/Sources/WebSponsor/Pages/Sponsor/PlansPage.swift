import Elementary
import SharedModels

public struct PlansPage: HTML {
  public let locale: SponsorPortalLocale
  public let plans: [SponsorPlanDTO]

  public init(locale: SponsorPortalLocale, plans: [SponsorPlanDTO]) {
    self.locale = locale
    self.plans = plans
  }

  public var body: some HTML {
    PortalLayout(
      pageTitle: PortalStrings.t(.plansTitle, locale),
      locale: locale, isAuthenticated: true
    ) {
      h1 { PortalStrings.t(.plansTitle, locale) }
      div(.class("plan-list")) {
        for p in plans { PlanCard(locale: locale, plan: p) }
      }
    }
  }
}
