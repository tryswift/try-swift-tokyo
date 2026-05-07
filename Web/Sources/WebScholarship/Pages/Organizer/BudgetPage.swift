import Elementary
import SharedModels

public struct BudgetPage: HTML {
  public let locale: ScholarshipPortalLocale
  public let apiBaseURL: String

  public init(locale: ScholarshipPortalLocale, apiBaseURL: String) {
    self.locale = locale
    self.apiBaseURL = apiBaseURL
  }

  public var body: some HTML {
    ScholarshipLayout(
      pageTitle: ScholarshipStrings.t(.orgBudgetTitle, locale),
      locale: locale,
      apiBaseURL: apiBaseURL,
      pageKind: "organizer-budget"
    ) {
      h1 { ScholarshipStrings.t(.orgBudgetTitle, locale) }

      section(.id("budget-summary")) {}

      form(
        .method(.post),
        .action("\(apiBaseURL)/api/v1/scholarship/organizer/budget"),
        .id("budget-form")
      ) {
        FormField(
          label: ScholarshipStrings.t(.orgTotalBudgetLabel, locale),
          name: "total_budget",
          inputType: "number",
          isRequired: true
        )
        FormTextArea(
          label: ScholarshipStrings.t(.orgBudgetNotesLabel, locale),
          name: "notes"
        )
        button(.type(.submit), .class("primary")) {
          ScholarshipStrings.t(.orgSaveBudget, locale)
        }
      }
    }
  }
}
