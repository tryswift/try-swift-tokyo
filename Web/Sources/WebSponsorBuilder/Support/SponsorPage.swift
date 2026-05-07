import SharedModels
import WebSponsor

enum SponsorPage: Sendable {
  case inquiry(SponsorPortalLocale)
  case inquiryThanks(SponsorPortalLocale)
  case loginRequest(SponsorPortalLocale)
  case loginSent(SponsorPortalLocale)

  func render(apiBaseURL: String) -> String {
    switch self {
    case .inquiry(let locale):
      return InquiryFormPage(locale: locale, csrfToken: "", apiBaseURL: apiBaseURL).render()
    case .inquiryThanks(let locale):
      return InquiryThanksPage(locale: locale, apiBaseURL: apiBaseURL).render()
    case .loginRequest(let locale):
      return LoginRequestPage(locale: locale, csrfToken: "", apiBaseURL: apiBaseURL).render()
    case .loginSent(let locale):
      return LoginSentPage(locale: locale, apiBaseURL: apiBaseURL).render()
    }
  }
}
