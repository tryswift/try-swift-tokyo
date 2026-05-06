import Elementary
import SharedModels

public struct ScholarshipNav: HTML {
  public let locale: ScholarshipPortalLocale
  public let isAuthenticated: Bool
  public let isOrganizer: Bool
  public let csrfToken: String

  public init(
    locale: ScholarshipPortalLocale,
    isAuthenticated: Bool,
    isOrganizer: Bool = false,
    csrfToken: String = ""
  ) {
    self.locale = locale
    self.isAuthenticated = isAuthenticated
    self.isOrganizer = isOrganizer
    self.csrfToken = csrfToken
  }

  public var body: some HTML {
    nav(.class("portal-nav")) {
      a(.href("/")) { "try! Swift Scholarship" }
      if isAuthenticated {
        a(.href("/apply")) { ScholarshipStrings.t(.navApply, locale) }
        a(.href("/my-application")) { ScholarshipStrings.t(.navMyApplication, locale) }
        form(.action("/logout"), .method(.post)) {
          input(.type(.hidden), .name("_csrf"), .value(csrfToken))
          button(.type(.submit)) { ScholarshipStrings.t(.navLogout, locale) }
        }
      } else {
        a(.href("/login")) { ScholarshipStrings.t(.navLogin, locale) }
      }
      if isOrganizer {
        a(.href("/organizer")) { ScholarshipStrings.t(.navOrganizer, locale) }
      }
    }
  }
}
