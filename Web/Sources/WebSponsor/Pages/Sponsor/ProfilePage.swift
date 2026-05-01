import Elementary
import SharedModels

public struct ProfilePage: HTML {
  public let locale: SponsorPortalLocale
  public let csrfToken: String
  public let legalName: String
  public let displayName: String
  public let country: String
  public let billingAddress: String
  public let websiteURL: String
  public let isOwner: Bool
  public let flash: String?

  public init(
    locale: SponsorPortalLocale, csrfToken: String,
    legalName: String, displayName: String,
    country: String, billingAddress: String, websiteURL: String,
    isOwner: Bool, flash: String? = nil
  ) {
    self.locale = locale
    self.csrfToken = csrfToken
    self.legalName = legalName
    self.displayName = displayName
    self.country = country
    self.billingAddress = billingAddress
    self.websiteURL = websiteURL
    self.isOwner = isOwner
    self.flash = flash
  }

  public var body: some HTML {
    PortalLayout(
      pageTitle: PortalStrings.t(.profileTitle, locale),
      locale: locale, isAuthenticated: true, flash: flash
    ) {
      h1 { PortalStrings.t(.profileTitle, locale) }
      form(.method(.post), .action("/profile")) {
        input(.type(.hidden), .name("_csrf"), .value(csrfToken))
        FormField(
          label: locale == .ja ? "正式社名" : "Legal name",
          name: "legalName", value: legalName, isRequired: true)
        FormField(
          label: locale == .ja ? "表示名" : "Display name",
          name: "displayName", value: displayName, isRequired: true)
        FormField(
          label: locale == .ja ? "国" : "Country",
          name: "country", value: country)
        FormField(
          label: locale == .ja ? "請求先住所" : "Billing address",
          name: "billingAddress", value: billingAddress)
        FormField(
          label: "Website", name: "websiteURL", value: websiteURL,
          inputType: "url")
        if isOwner {
          button(.type(.submit)) { locale == .ja ? "保存" : "Save" }
        } else {
          p { locale == .ja ? "編集はオーナーのみ可能です。" : "Only the owner can edit." }
        }
      }
    }
  }
}
