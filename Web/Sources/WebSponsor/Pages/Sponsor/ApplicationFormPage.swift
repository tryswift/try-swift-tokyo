import Elementary
import SharedModels

public struct ApplicationFormPage: HTML {
  public let locale: SponsorPortalLocale
  public let csrfToken: String
  public let plans: [SponsorPlanDTO]
  public let preselectedSlug: String?

  public init(
    locale: SponsorPortalLocale, csrfToken: String,
    plans: [SponsorPlanDTO], preselectedSlug: String?
  ) {
    self.locale = locale
    self.csrfToken = csrfToken
    self.plans = plans
    self.preselectedSlug = preselectedSlug
  }

  public var body: some HTML {
    PortalLayout(
      pageTitle: PortalStrings.t(.applicationFormTitle, locale),
      locale: locale, isAuthenticated: true
    ) {
      h1 { PortalStrings.t(.applicationFormTitle, locale) }
      form(.method(.post), .action("/applications")) {
        input(.type(.hidden), .name("_csrf"), .value(csrfToken))
        div(.class("form-field")) {
          Elementary.label(.for("planSlug")) { locale == .ja ? "プラン" : "Plan" }
          select(.name("planSlug"), .id("planSlug")) {
            for p in plans {
              let label = p.localized(for: locale)?.name ?? p.slug
              if p.slug == preselectedSlug {
                option(.value(p.slug), .custom(name: "selected", value: "selected")) { label }
              } else {
                option(.value(p.slug)) { label }
              }
            }
          }
        }
        FormField(
          label: locale == .ja ? "請求担当者名" : "Billing contact name",
          name: "billingContactName", isRequired: true)
        FormField(
          label: locale == .ja ? "請求先メール" : "Billing email",
          name: "billingEmail", inputType: "email", isRequired: true)
        FormField(
          label: locale == .ja ? "請求備考" : "Invoicing notes",
          name: "invoicingNotes")
        FormField(
          label: locale == .ja ? "ロゴ補足" : "Logo note",
          name: "logoNote")
        div(.class("form-field")) {
          Elementary.label(.for("acceptedTerms")) {
            input(
              .type(.checkbox), .name("acceptedTerms"), .id("acceptedTerms"),
              .value("true"), .custom(name: "required", value: "required"))
            locale == .ja ? "規約に同意します" : "I accept the terms"
          }
        }
        button(.type(.submit)) { PortalStrings.t(.applicationSubmit, locale) }
      }
    }
  }
}
