import Elementary
import SharedModels

public struct PortalNav: HTML {
  public let locale: SponsorPortalLocale
  public let isAuthenticated: Bool
  public let csrfToken: String

  public init(locale: SponsorPortalLocale, isAuthenticated: Bool, csrfToken: String = "") {
    self.locale = locale
    self.isAuthenticated = isAuthenticated
    self.csrfToken = csrfToken
  }

  public var body: some HTML {
    nav(.class("portal-nav")) {
      a(.href("/")) { "try! Swift Sponsor" }
      if isAuthenticated {
        a(.href("/dashboard")) { PortalStrings.t(.dashboardTitle, locale) }
        a(.href("/team")) { PortalStrings.t(.teamTitle, locale) }
        form(.action("/logout"), .method(.post)) {
          input(.type(.hidden), .name("_csrf"), .value(csrfToken))
          button(.type(.submit)) { "Logout" }
        }
      } else {
        a(.href("/login")) { PortalStrings.t(.loginTitle, locale) }
      }
    }
  }
}
