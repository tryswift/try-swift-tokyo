import Elementary
import SharedModels

/// Landing page on student.tryswift.jp. Shows the scholarship summary and
/// (when an organizer has set one) the remaining budget.
public struct InfoPage: HTML {
  public let locale: ScholarshipPortalLocale
  public let isAuthenticated: Bool
  public let conferenceName: String?
  public let budget: ScholarshipBudgetSummaryDTO?

  public init(
    locale: ScholarshipPortalLocale,
    isAuthenticated: Bool,
    conferenceName: String?,
    budget: ScholarshipBudgetSummaryDTO?
  ) {
    self.locale = locale
    self.isAuthenticated = isAuthenticated
    self.conferenceName = conferenceName
    self.budget = budget
  }

  public var body: some HTML {
    ScholarshipLayout(
      pageTitle: ScholarshipStrings.t(.infoTitle, locale),
      locale: locale,
      isAuthenticated: isAuthenticated
    ) {
      h1 { ScholarshipStrings.t(.infoTitle, locale) }
      if let conferenceName {
        p(.class("subtitle")) {
          "\(conferenceName) — \(ScholarshipStrings.t(.infoSubtitle, locale))"
        }
      } else {
        p(.class("subtitle")) { ScholarshipStrings.t(.infoNoOpenConference, locale) }
      }

      section(.class("budget-summary")) {
        h2 { ScholarshipStrings.t(.infoBudgetTotal, locale) }
        if let budget, let total = budget.totalBudget {
          dl {
            dt { ScholarshipStrings.t(.infoBudgetTotal, locale) }
            dd { "¥\(total)" }
            dt { ScholarshipStrings.t(.infoBudgetApproved, locale) }
            dd { "¥\(budget.approvedTotal)" }
            if let remaining = budget.remaining {
              dt { ScholarshipStrings.t(.infoBudgetRemaining, locale) }
              dd { "¥\(remaining)" }
            }
          }
        } else {
          p { ScholarshipStrings.t(.infoBudgetNotSet, locale) }
        }
      }

      if conferenceName != nil {
        a(.href(isAuthenticated ? "/apply" : "/login"), .class("cta")) {
          ScholarshipStrings.t(.infoApplyCTA, locale)
        }
      }
    }
  }
}
