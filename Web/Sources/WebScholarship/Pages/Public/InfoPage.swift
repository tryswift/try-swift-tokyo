import Elementary
import SharedModels

/// Landing page on student.tryswift.jp. Conference name and budget are
/// rendered client-side by `scholarship.js` after fetching `/api/v1/scholarship/info`.
public struct InfoPage: HTML {
  public let locale: ScholarshipPortalLocale
  public let apiBaseURL: String

  public init(locale: ScholarshipPortalLocale, apiBaseURL: String) {
    self.locale = locale
    self.apiBaseURL = apiBaseURL
  }

  public var body: some HTML {
    ScholarshipLayout(
      pageTitle: ScholarshipStrings.t(.infoTitle, locale),
      locale: locale,
      apiBaseURL: apiBaseURL,
      pageKind: "info"
    ) {
      h1 { ScholarshipStrings.t(.infoTitle, locale) }
      p(.class("subtitle"), .id("conference-info")) {
        ScholarshipStrings.t(.infoSubtitle, locale)
      }

      section(.class("budget-summary"), .id("budget-summary")) {
        h2 { ScholarshipStrings.t(.infoBudgetTotal, locale) }
        p { ScholarshipStrings.t(.infoBudgetNotSet, locale) }
      }

      a(.href(locale == .ja ? "/ja/login" : "/login"), .class("cta"), .id("apply-cta")) {
        ScholarshipStrings.t(.infoApplyCTA, locale)
      }
    }
  }
}
