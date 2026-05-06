import Elementary
import SharedModels

public struct MyApplicationPage: HTML {
  public let locale: ScholarshipPortalLocale
  public let csrfToken: String
  public let application: ScholarshipApplicationDTO?
  public let flash: String?

  public init(
    locale: ScholarshipPortalLocale,
    csrfToken: String,
    application: ScholarshipApplicationDTO?,
    flash: String? = nil
  ) {
    self.locale = locale
    self.csrfToken = csrfToken
    self.application = application
    self.flash = flash
  }

  public var body: some HTML {
    ScholarshipLayout(
      pageTitle: ScholarshipStrings.t(.myAppTitle, locale),
      locale: locale,
      isAuthenticated: true,
      flash: flash,
      csrfToken: csrfToken
    ) {
      h1 { ScholarshipStrings.t(.myAppTitle, locale) }
      if let app = application {
        section(.class("my-app")) {
          dl {
            dt { ScholarshipStrings.t(.myAppStatusLabel, locale) }
            dd { StatusBadge(status: app.status, locale: locale) }
            dt { ScholarshipStrings.t(.applyEmailLabel, locale) }
            dd { app.email }
            dt { ScholarshipStrings.t(.applyNameLabel, locale) }
            dd { app.name }
            dt { ScholarshipStrings.t(.applySchoolLabel, locale) }
            dd { app.schoolAndFaculty }
            dt { ScholarshipStrings.t(.applyYearLabel, locale) }
            dd { app.currentYear }
            dt { ScholarshipStrings.t(.applySupportTypeLabel, locale) }
            dd {
              locale == .ja ? app.supportType.displayNameJa : app.supportType.displayName
            }
            if let approved = app.approvedAmount {
              dt { ScholarshipStrings.t(.myAppApprovedAmount, locale) }
              dd { "¥\(approved)" }
            }
          }

          if app.status == .submitted {
            form(
              .method(.post),
              .action("/my-application/withdraw"),
              .custom(
                name: "onsubmit",
                value:
                  "return confirm('\(ScholarshipStrings.t(.myAppWithdrawConfirm, locale))')")
            ) {
              input(.type(.hidden), .name("_csrf"), .value(csrfToken))
              button(.type(.submit), .class("danger")) {
                ScholarshipStrings.t(.myAppWithdraw, locale)
              }
            }
          }
        }
      } else {
        p { ScholarshipStrings.t(.myAppNoApplication, locale) }
        a(.href("/apply"), .class("cta")) {
          ScholarshipStrings.t(.infoApplyCTA, locale)
        }
      }
    }
  }
}
