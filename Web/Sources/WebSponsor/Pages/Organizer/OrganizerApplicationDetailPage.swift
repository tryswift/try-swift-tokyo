import Elementary
import SharedModels

public struct OrganizerApplicationDetailPage: HTML {
  public let locale: SponsorPortalLocale
  public let csrfToken: String
  public let application: SponsorApplicationDTO
  public let orgName: String
  public let planName: String

  public init(
    locale: SponsorPortalLocale, csrfToken: String,
    application: SponsorApplicationDTO,
    orgName: String, planName: String
  ) {
    self.locale = locale
    self.csrfToken = csrfToken
    self.application = application
    self.orgName = orgName
    self.planName = planName
  }

  public var body: some HTML {
    PortalLayout(
      pageTitle: PortalStrings.t(.applicationDetailTitle, locale),
      locale: locale, isAuthenticated: true
    ) {
      h1 { "\(orgName) — \(planName)" }
      p { StatusBadge(application.status) }
      p {
        "\(locale == .ja ? "請求担当" : "Billing"): \(application.payload.billingContactName) <\(application.payload.billingEmail)>"
      }
      if application.status == .submitted || application.status == .underReview {
        h2 { locale == .ja ? "判定" : "Decision" }
        form(.method(.post), .action("/admin/applications/\(application.id.uuidString)/approve")) {
          input(.type(.hidden), .name("_csrf"), .value(csrfToken))
          button(.type(.submit)) { locale == .ja ? "承認する" : "Approve" }
        }
        form(.method(.post), .action("/admin/applications/\(application.id.uuidString)/reject")) {
          input(.type(.hidden), .name("_csrf"), .value(csrfToken))
          FormField(
            label: locale == .ja ? "却下理由" : "Rejection reason",
            name: "reason", isRequired: true)
          button(.type(.submit)) { locale == .ja ? "却下する" : "Reject" }
        }
      } else if let note = application.decisionNote {
        p { "\(locale == .ja ? "理由" : "Reason"): \(note)" }
      }
    }
  }
}
