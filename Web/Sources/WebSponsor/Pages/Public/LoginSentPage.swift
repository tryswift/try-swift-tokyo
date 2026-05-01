import Elementary
import SharedModels

public struct LoginSentPage: HTML {
  public let locale: SponsorPortalLocale

  public init(locale: SponsorPortalLocale) { self.locale = locale }

  public var body: some HTML {
    PortalLayout(pageTitle: "OK", locale: locale, isAuthenticated: false) {
      h1 { locale == .ja ? "ログインリンクをお送りしました" : "Login link sent" }
      p {
        locale == .ja
          ? "メールをご確認ください。30分以内にリンクをクリックしてください。"
          : "Check your inbox; link expires in 30 minutes."
      }
    }
  }
}
