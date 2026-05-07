import Elementary
import SharedModels

public struct InquiryThanksPage: HTML {
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
      h1 { locale == .ja ? "資料請求を受け付けました" : "Materials request received" }
      p { locale == .ja ? "ご登録のメールアドレスにログインリンクをお送りしました。" : "We've emailed you a login link." }
    }
  }
}
