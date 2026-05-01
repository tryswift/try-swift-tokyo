import Elementary
import SharedModels

public struct PortalNav: HTML {
  public let locale: SponsorPortalLocale
  public let isAuthenticated: Bool

  public init(locale: SponsorPortalLocale, isAuthenticated: Bool) {
    self.locale = locale
    self.isAuthenticated = isAuthenticated
  }

  public var body: some HTML {
    nav(.class("portal-nav")) {
      a(.href("/")) { "try! Swift Sponsor" }
      if isAuthenticated {
        a(.href("/dashboard")) { PortalStrings.t(.dashboardTitle, locale) }
        a(.href("/team")) { PortalStrings.t(.teamTitle, locale) }
        form(.action("/logout"), .method(.post)) {
          button(.type(.submit)) { "Logout" }
        }
      } else {
        a(.href("/login")) { PortalStrings.t(.loginTitle, locale) }
      }
    }
  }
}
