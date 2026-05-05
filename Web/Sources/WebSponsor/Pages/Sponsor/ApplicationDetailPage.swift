import Elementary
import SharedModels

public struct ApplicationDetailPage: HTML {
  public let locale: SponsorPortalLocale
  public let csrfToken: String
  public let application: SponsorApplicationDTO
  public let planName: String
  public let canWithdraw: Bool

  public init(
    locale: SponsorPortalLocale, csrfToken: String,
    application: SponsorApplicationDTO, planName: String, canWithdraw: Bool
  ) {
    self.locale = locale
    self.csrfToken = csrfToken
    self.application = application
    self.planName = planName
    self.canWithdraw = canWithdraw
  }

  public var body: some HTML {
    PortalLayout(
      pageTitle: PortalStrings.t(.applicationDetailTitle, locale),
      locale: locale, isAuthenticated: true, csrfToken: csrfToken
    ) {
      h1 { PortalStrings.t(.applicationDetailTitle, locale) }
      p { "Plan: \(planName)" }
      p {
        StatusBadge(application.status)
      }
      p {
        "\(locale == .ja ? "請求担当" : "Billing contact"): \(application.payload.billingContactName) <\(application.payload.billingEmail)>"
      }
      if let note = application.decisionNote {
        p { "\(locale == .ja ? "コメント" : "Note"): \(note)" }
      }
      if canWithdraw {
        form(
          .method(.post),
          .action("/applications/\(application.id.uuidString)/withdraw")
        ) {
          input(.type(.hidden), .name("_csrf"), .value(csrfToken))
          button(.type(.submit)) { locale == .ja ? "申込を取り下げる" : "Withdraw" }
        }
      }
    }
  }
}
