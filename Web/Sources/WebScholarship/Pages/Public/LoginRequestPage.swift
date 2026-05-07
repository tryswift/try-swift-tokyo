import Elementary
import SharedModels

public struct LoginRequestPage: HTML {
  public let locale: ScholarshipPortalLocale
  public let apiBaseURL: String

  public init(locale: ScholarshipPortalLocale, apiBaseURL: String) {
    self.locale = locale
    self.apiBaseURL = apiBaseURL
  }

  public var body: some HTML {
    ScholarshipLayout(
      pageTitle: ScholarshipStrings.t(.loginTitle, locale),
      locale: locale,
      apiBaseURL: apiBaseURL,
      pageKind: "login"
    ) {
      h1 { ScholarshipStrings.t(.loginTitle, locale) }
      form(
        .method(.post),
        .action("\(apiBaseURL)/api/v1/scholarship/login"),
        .id("login-form")
      ) {
        FormField(
          label: ScholarshipStrings.t(.loginEmailLabel, locale),
          name: "email",
          inputType: "email",
          isRequired: true
        )
        input(
          .type(.hidden),
          .name("redirect_to"),
          .value("\(redirectBase())/login/sent")
        )
        button(.type(.submit)) { ScholarshipStrings.t(.loginSubmit, locale) }
      }
    }
  }

  private func redirectBase() -> String {
    // The API redirect flips the user back to the static portal after
    // queueing the magic-link email; the value is templated at build time
    // because the static site has no server-side request to derive it from.
    locale == .ja ? "/ja" : ""
  }
}
