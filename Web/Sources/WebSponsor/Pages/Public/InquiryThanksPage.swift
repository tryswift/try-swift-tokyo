import Elementary
import SharedModels

public struct InquiryThanksPage: HTML {
  public let locale: SponsorPortalLocale

  public init(locale: SponsorPortalLocale) { self.locale = locale }

  public var body: some HTML {
    PortalLayout(pageTitle: "OK", locale: locale, isAuthenticated: false) {
      h1 { locale == .ja ? "資料請求を受け付けました" : "Materials request received" }
      p { locale == .ja ? "ご登録のメールアドレスにログインリンクをお送りしました。" : "We've emailed you a login link." }
    }
  }
}
