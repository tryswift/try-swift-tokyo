import Elementary
import SharedModels

public struct OrganizerInquiryListPage: HTML {
  public let locale: SponsorPortalLocale
  public let csrfToken: String
  public let inquiries: [SponsorInquiryDTO]

  public init(locale: SponsorPortalLocale, csrfToken: String = "", inquiries: [SponsorInquiryDTO]) {
    self.locale = locale
    self.csrfToken = csrfToken
    self.inquiries = inquiries
  }

  public var body: some HTML {
    PortalLayout(
      pageTitle: PortalStrings.t(.organizerInquiries, locale),
      locale: locale, isAuthenticated: true, csrfToken: csrfToken
    ) {
      h1 { PortalStrings.t(.organizerInquiries, locale) }
      table {
        thead {
          tr {
            th { locale == .ja ? "会社" : "Company" }
            th { locale == .ja ? "担当者" : "Contact" }
            th { "Email" }
            th { locale == .ja ? "希望プラン" : "Plan" }
          }
        }
        tbody {
          for q in inquiries {
            tr {
              td { q.companyName }
              td { q.contactName }
              td { q.email }
              td { q.desiredPlanSlug ?? "" }
            }
          }
        }
      }
    }
  }
}
