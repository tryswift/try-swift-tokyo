import Elementary
import SharedModels

public struct ApplicationListPage: HTML {
  public let locale: ScholarshipPortalLocale
  public let apiBaseURL: String

  public init(locale: ScholarshipPortalLocale, apiBaseURL: String) {
    self.locale = locale
    self.apiBaseURL = apiBaseURL
  }

  public var body: some HTML {
    ScholarshipLayout(
      pageTitle: ScholarshipStrings.t(.orgListTitle, locale),
      locale: locale,
      apiBaseURL: apiBaseURL,
      pageKind: "organizer-list"
    ) {
      h1 { ScholarshipStrings.t(.orgListTitle, locale) }

      section(.id("budget-summary"), .class("budget-summary")) {}

      div(.class("toolbar")) {
        a(.href("\(apiBaseURL)/api/v1/scholarship/organizer/applications.csv")) {
          ScholarshipStrings.t(.orgExportCSV, locale)
        }
        a(.href(locale == .ja ? "/ja/organizer/budget" : "/organizer/budget")) {
          ScholarshipStrings.t(.orgBudgetTitle, locale)
        }
      }

      table(.class("applications"), .id("applications-table")) {
        thead {
          tr {
            th { "#" }
            th { ScholarshipStrings.t(.applyNameLabel, locale) }
            th { ScholarshipStrings.t(.applySchoolLabel, locale) }
            th { ScholarshipStrings.t(.applySupportTypeLabel, locale) }
            th { ScholarshipStrings.t(.myAppStatusLabel, locale) }
            th { ScholarshipStrings.t(.myAppApprovedAmount, locale) }
            th { "" }
          }
        }
        tbody(.id("applications-tbody")) {}
      }
    }
  }
}
