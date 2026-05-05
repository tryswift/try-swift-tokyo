import Elementary
import SharedModels

public struct InvitationAcceptPage: HTML {
  public let locale: SponsorPortalLocale
  public let orgName: String
  public let token: String
  public let csrfToken: String

  public init(locale: SponsorPortalLocale, orgName: String, token: String, csrfToken: String) {
    self.locale = locale
    self.orgName = orgName
    self.token = token
    self.csrfToken = csrfToken
  }

  public var body: some HTML {
    PortalLayout(
      pageTitle: locale == .ja ? "招待を受諾" : "Accept invitation",
      locale: locale, isAuthenticated: false, csrfToken: csrfToken
    ) {
      h1 { locale == .ja ? "\(orgName) への参加" : "Join \(orgName)" }
      form(.method(.post), .action("/invitations/\(token)/accept")) {
        input(.type(.hidden), .name("_csrf"), .value(csrfToken))
        button(.type(.submit)) { locale == .ja ? "受諾する" : "Accept" }
      }
    }
  }
}
