import Elementary
import SharedModels

public struct DashboardPage: HTML {
  public let locale: SponsorPortalLocale
  public let userEmail: String
  public let orgName: String?

  public init(locale: SponsorPortalLocale, userEmail: String, orgName: String?) {
    self.locale = locale
    self.userEmail = userEmail
    self.orgName = orgName
  }

  public var body: some HTML {
    PortalLayout(
      pageTitle: PortalStrings.t(.dashboardTitle, locale), locale: locale, isAuthenticated: true
    ) {
      h1 { PortalStrings.t(.dashboardTitle, locale) }
      p { "\(locale == .ja ? "ようこそ" : "Welcome"), \(userEmail)" }
      if let orgName {
        p { orgName }
      } else {
        p {
          a(.href("/profile")) {
            locale == .ja ? "組織情報を登録する" : "Set up your organization"
          }
        }
      }
      ul {
        li { a(.href("/plans")) { PortalStrings.t(.plansTitle, locale) } }
        li { a(.href("/team")) { PortalStrings.t(.teamTitle, locale) } }
      }
    }
  }
}
