import Elementary
import SharedModels

public struct OrganizerSponsorDetailPage: HTML {
  public let locale: SponsorPortalLocale
  public let csrfToken: String
  public let organization: SponsorOrganizationDTO
  public let memberEmails: [String]
  public let applications: [(id: String, planSlug: String, status: SponsorApplicationStatus)]

  public init(
    locale: SponsorPortalLocale,
    csrfToken: String = "",
    organization: SponsorOrganizationDTO,
    memberEmails: [String],
    applications: [(id: String, planSlug: String, status: SponsorApplicationStatus)]
  ) {
    self.locale = locale
    self.csrfToken = csrfToken
    self.organization = organization
    self.memberEmails = memberEmails
    self.applications = applications
  }

  public var body: some HTML {
    PortalLayout(
      pageTitle: organization.displayName,
      locale: locale, isAuthenticated: true, csrfToken: csrfToken
    ) {
      h1 { organization.displayName }
      p { organization.legalName }
      if let url = organization.websiteURL { p { url } }
      h2 { locale == .ja ? "メンバー" : "Members" }
      ul { for e in memberEmails { li { e } } }
      h2 { locale == .ja ? "申込" : "Applications" }
      ul {
        for app in applications {
          li {
            a(.href("/admin/applications/\(app.id)")) { app.planSlug }
            " — "
            StatusBadge(app.status)
          }
        }
      }
    }
  }
}
