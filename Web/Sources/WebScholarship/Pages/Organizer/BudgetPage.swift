import Elementary
import SharedModels

public struct BudgetPage: HTML {
  public let locale: ScholarshipPortalLocale
  public let csrfToken: String
  public let budget: ScholarshipBudgetDTO?
  public let summary: ScholarshipBudgetSummaryDTO?

  public init(
    locale: ScholarshipPortalLocale,
    csrfToken: String,
    budget: ScholarshipBudgetDTO?,
    summary: ScholarshipBudgetSummaryDTO?
  ) {
    self.locale = locale
    self.csrfToken = csrfToken
    self.budget = budget
    self.summary = summary
  }

  public var body: some HTML {
    ScholarshipLayout(
      pageTitle: ScholarshipStrings.t(.orgBudgetTitle, locale),
      locale: locale,
      isAuthenticated: true,
      isOrganizer: true,
      csrfToken: csrfToken
    ) {
      h1 { ScholarshipStrings.t(.orgBudgetTitle, locale) }

      if let summary {
        dl {
          dt { ScholarshipStrings.t(.infoBudgetApproved, locale) }
          dd { "¥\(summary.approvedTotal)" }
          if let r = summary.remaining {
            dt { ScholarshipStrings.t(.infoBudgetRemaining, locale) }
            dd { "¥\(r)" }
          }
        }
      }

      form(.method(.post), .action("/organizer/budget")) {
        input(.type(.hidden), .name("_csrf"), .value(csrfToken))
        FormField(
          label: ScholarshipStrings.t(.orgTotalBudgetLabel, locale),
          name: "total_budget",
          value: budget.map { String($0.totalBudget) } ?? "",
          inputType: "number",
          isRequired: true
        )
        FormTextArea(
          label: ScholarshipStrings.t(.orgBudgetNotesLabel, locale),
          name: "notes",
          value: budget?.notes ?? ""
        )
        button(.type(.submit), .class("primary")) {
          ScholarshipStrings.t(.orgSaveBudget, locale)
        }
      }
    }
  }
}
