import Elementary
import SharedModels
import WebShared

public struct PortalLayout<Inner: HTML>: HTML {
  public let pageTitle: String
  public let locale: SponsorPortalLocale
  public let isAuthenticated: Bool
  public let flash: String?
  public let inner: Inner

  public init(
    pageTitle: String,
    locale: SponsorPortalLocale,
    isAuthenticated: Bool,
    flash: String? = nil,
    @HTMLBuilder inner: () -> Inner
  ) {
    self.pageTitle = pageTitle
    self.locale = locale
    self.isAuthenticated = isAuthenticated
    self.flash = flash
    self.inner = inner()
  }

  public var body: some HTML {
    let webLocale: WebLocale = locale == .ja ? .ja : .en
    WebLayout(pageTitle: pageTitle, locale: webLocale) {
      PortalNav(locale: locale, isAuthenticated: isAuthenticated)
      if let flash {
        div(.class("flash")) { flash }
      }
      main(.class("portal-main")) { inner }
    }
  }
}
