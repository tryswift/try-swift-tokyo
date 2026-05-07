import Elementary
import SharedModels

public struct LoginSentPage: HTML {
  public let locale: SponsorPortalLocale
  public let apiBaseURL: String?

  public init(locale: SponsorPortalLocale, apiBaseURL: String? = nil) {
    self.locale = locale
    self.apiBaseURL = apiBaseURL
  }

  public var body: some HTML {
    PortalLayout(
      pageTitle: "OK",
      locale: locale,
      isAuthenticated: false,
      apiBaseURL: apiBaseURL
    ) {
      h1 { locale == .ja ? "ログインリンクをお送りしました" : "Login link sent" }
      p {
        locale == .ja
          ? "メールをご確認ください。30分以内にリンクをクリックしてください。"
          : "Check your inbox; link expires in 30 minutes."
      }
    }
  }
}
