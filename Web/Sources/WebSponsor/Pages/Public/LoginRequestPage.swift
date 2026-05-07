import Elementary
import SharedModels

public struct LoginRequestPage: HTML {
  public let locale: SponsorPortalLocale
  public let csrfToken: String
  public let errorMessage: String?
  public let apiBaseURL: String?

  public init(
    locale: SponsorPortalLocale,
    csrfToken: String,
    errorMessage: String? = nil,
    apiBaseURL: String? = nil
  ) {
    self.locale = locale
    self.csrfToken = csrfToken
    self.errorMessage = errorMessage
    self.apiBaseURL = apiBaseURL
  }

  public var body: some HTML {
    PortalLayout(
      pageTitle: PortalStrings.t(.loginTitle, locale),
      locale: locale,
      isAuthenticated: false,
      flash: errorMessage,
      apiBaseURL: apiBaseURL
    ) {
      h1 { PortalStrings.t(.loginTitle, locale) }
      form(.method(.post), .action("/login")) {
        input(.type(.hidden), .name("_csrf"), .value(csrfToken))
        FormField(label: "Email", name: "email", inputType: "email", isRequired: true)
        button(.type(.submit)) { PortalStrings.t(.loginSubmit, locale) }
      }
    }
  }
}
