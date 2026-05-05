import Elementary
import SharedModels

public struct LoginRequestPage: HTML {
  public let locale: SponsorPortalLocale
  public let csrfToken: String
  public let errorMessage: String?

  public init(locale: SponsorPortalLocale, csrfToken: String, errorMessage: String? = nil) {
    self.locale = locale
    self.csrfToken = csrfToken
    self.errorMessage = errorMessage
  }

  public var body: some HTML {
    PortalLayout(
      pageTitle: PortalStrings.t(.loginTitle, locale),
      locale: locale,
      isAuthenticated: false,
      flash: errorMessage
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
