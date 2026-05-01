import Elementary
import SharedModels

public struct OrganizerSponsorListPage: HTML {
  public struct Row: Sendable {
    public let id: String
    public let displayName: String
    public let memberCount: Int
    public let applicationCount: Int
    public init(id: String, displayName: String, memberCount: Int, applicationCount: Int) {
      self.id = id
      self.displayName = displayName
      self.memberCount = memberCount
      self.applicationCount = applicationCount
    }
  }

  public let locale: SponsorPortalLocale
  public let rows: [Row]

  public init(locale: SponsorPortalLocale, rows: [Row]) {
    self.locale = locale
    self.rows = rows
  }

  public var body: some HTML {
    PortalLayout(
      pageTitle: PortalStrings.t(.organizerSponsors, locale),
      locale: locale, isAuthenticated: true
    ) {
      h1 { PortalStrings.t(.organizerSponsors, locale) }
      table {
        thead {
          tr {
            th { locale == .ja ? "会社名" : "Company" }
            th { locale == .ja ? "メンバー数" : "Members" }
            th { locale == .ja ? "申込数" : "Applications" }
          }
        }
        tbody {
          for r in rows {
            tr {
              td { a(.href("/admin/sponsors/\(r.id)")) { r.displayName } }
              td { String(r.memberCount) }
              td { String(r.applicationCount) }
            }
          }
        }
      }
    }
  }
}
