import Elementary
import SharedModels

public struct LoginRequestPage: HTML {
  public let locale: ScholarshipPortalLocale
  public let csrfToken: String
  public let errorMessage: String?

  public init(locale: ScholarshipPortalLocale, csrfToken: String, errorMessage: String? = nil) {
    self.locale = locale
    self.csrfToken = csrfToken
    self.errorMessage = errorMessage
  }

  public var body: some HTML {
    ScholarshipLayout(
      pageTitle: ScholarshipStrings.t(.loginTitle, locale),
      locale: locale,
      isAuthenticated: false,
      flash: errorMessage
    ) {
      h1 { ScholarshipStrings.t(.loginTitle, locale) }
      form(.method(.post), .action("/login")) {
        input(.type(.hidden), .name("_csrf"), .value(csrfToken))
        FormField(
          label: ScholarshipStrings.t(.loginEmailLabel, locale),
          name: "email",
          inputType: "email",
          isRequired: true
        )
        button(.type(.submit)) { ScholarshipStrings.t(.loginSubmit, locale) }
      }
    }
  }
}
