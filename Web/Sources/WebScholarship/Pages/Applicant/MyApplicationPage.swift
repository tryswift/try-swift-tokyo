import Elementary
import SharedModels

public struct MyApplicationPage: HTML {
  public let locale: ScholarshipPortalLocale
  public let apiBaseURL: String

  public init(locale: ScholarshipPortalLocale, apiBaseURL: String) {
    self.locale = locale
    self.apiBaseURL = apiBaseURL
  }

  public var body: some HTML {
    ScholarshipLayout(
      pageTitle: ScholarshipStrings.t(.myAppTitle, locale),
      locale: locale,
      apiBaseURL: apiBaseURL,
      pageKind: "my-application"
    ) {
      h1 { ScholarshipStrings.t(.myAppTitle, locale) }
      // scholarship.js fills `#my-application` with a populated <dl> after
      // fetching `/api/v1/scholarship/me/application`. The empty-state copy
      // is replaced when an application exists.
      section(.id("my-application")) {
        p { ScholarshipStrings.t(.myAppNoApplication, locale) }
      }
      form(
        .method(.post),
        .action("\(apiBaseURL)/api/v1/scholarship/me/application/withdraw"),
        .id("withdraw-form"),
        .class("hidden")
      ) {
        button(.type(.submit), .class("danger")) {
          ScholarshipStrings.t(.myAppWithdraw, locale)
        }
      }
    }
  }
}
