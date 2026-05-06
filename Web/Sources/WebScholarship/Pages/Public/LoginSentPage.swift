import Elementary
import SharedModels

public struct LoginSentPage: HTML {
  public let locale: ScholarshipPortalLocale

  public init(locale: ScholarshipPortalLocale) {
    self.locale = locale
  }

  public var body: some HTML {
    ScholarshipLayout(
      pageTitle: ScholarshipStrings.t(.loginSentTitle, locale),
      locale: locale,
      isAuthenticated: false
    ) {
      h1 { ScholarshipStrings.t(.loginSentTitle, locale) }
      p { ScholarshipStrings.t(.loginSentBody, locale) }
    }
  }
}
