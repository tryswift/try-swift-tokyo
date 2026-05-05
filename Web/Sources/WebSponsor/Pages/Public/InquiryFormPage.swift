import Elementary
import SharedModels

public struct InquiryFormPage: HTML {
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
      pageTitle: PortalStrings.t(.inquiryTitle, locale),
      locale: locale,
      isAuthenticated: false,
      flash: errorMessage
    ) {
      h1 { PortalStrings.t(.inquiryTitle, locale) }
      form(.method(.post), .action("/inquiry")) {
        input(.type(.hidden), .name("_csrf"), .value(csrfToken))
        FormField(
          label: locale == .ja ? "会社名" : "Company name",
          name: "companyName",
          isRequired: true
        )
        FormField(
          label: locale == .ja ? "ご担当者名" : "Contact name",
          name: "contactName",
          isRequired: true
        )
        FormField(label: "Email", name: "email", inputType: "email", isRequired: true)
        FormField(
          label: locale == .ja ? "ご質問・希望プラン等" : "Notes / desired plan",
          name: "message"
        )
        button(.type(.submit)) { PortalStrings.t(.inquirySubmit, locale) }
      }
    }
  }
}
