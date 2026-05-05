import Elementary
import SharedModels

public struct OrganizerApplicationListPage: HTML {
  public struct Row: Sendable {
    public let id: String
    public let orgName: String
    public let planSlug: String
    public let status: SponsorApplicationStatus
    public init(id: String, orgName: String, planSlug: String, status: SponsorApplicationStatus) {
      self.id = id
      self.orgName = orgName
      self.planSlug = planSlug
      self.status = status
    }
  }

  public let locale: SponsorPortalLocale
  public let csrfToken: String
  public let rows: [Row]

  public init(locale: SponsorPortalLocale, csrfToken: String = "", rows: [Row]) {
    self.locale = locale
    self.csrfToken = csrfToken
    self.rows = rows
  }

  public var body: some HTML {
    PortalLayout(
      pageTitle: PortalStrings.t(.organizerApplications, locale),
      locale: locale, isAuthenticated: true, csrfToken: csrfToken
    ) {
      h1 { PortalStrings.t(.organizerApplications, locale) }
      table {
        thead {
          tr {
            th { locale == .ja ? "会社" : "Company" }
            th { locale == .ja ? "プラン" : "Plan" }
            th { locale == .ja ? "ステータス" : "Status" }
            th { "" }
          }
        }
        tbody {
          for r in rows {
            tr {
              td { r.orgName }
              td { r.planSlug }
              td { StatusBadge(r.status) }
              td { a(.href("/admin/applications/\(r.id)")) { locale == .ja ? "詳細" : "View" } }
            }
          }
        }
      }
    }
  }
}
