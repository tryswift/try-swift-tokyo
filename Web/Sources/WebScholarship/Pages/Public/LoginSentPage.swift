import Elementary
import SharedModels

public struct LoginSentPage: HTML {
  public let locale: ScholarshipPortalLocale
  public let apiBaseURL: String

  public init(locale: ScholarshipPortalLocale, apiBaseURL: String) {
    self.locale = locale
    self.apiBaseURL = apiBaseURL
  }

  public var body: some HTML {
    ScholarshipLayout(
      pageTitle: ScholarshipStrings.t(.loginSentTitle, locale),
      locale: locale,
      apiBaseURL: apiBaseURL,
      pageKind: "login-sent"
    ) {
      h1 { ScholarshipStrings.t(.loginSentTitle, locale) }
      p { ScholarshipStrings.t(.loginSentBody, locale) }
    }
  }
}
