import Elementary
import SharedModels

/// Navigation bar. Auth-dependent links are emitted with `data-auth-state`
/// markers so `scholarship.js` can show/hide them after fetching `/me`.
public struct ScholarshipNav: HTML {
  public let locale: ScholarshipPortalLocale

  public init(locale: ScholarshipPortalLocale) {
    self.locale = locale
  }

  public var body: some HTML {
    nav(.class("portal-nav")) {
      a(.href(rootHref)) { "try! Swift Scholarship" }

      // Public links (always visible).
      a(
        .href(prefixed("/login")), .class("nav-link"),
        .custom(name: "data-auth-state", value: "signed-out"),
        .custom(name: "hidden", value: "hidden")
      ) {
        ScholarshipStrings.t(.navLogin, locale)
      }

      // Authenticated-applicant links (hidden until `/me` succeeds).
      a(
        .href(prefixed("/apply")), .class("nav-link"),
        .custom(name: "data-auth-state", value: "signed-in"),
        .custom(name: "hidden", value: "hidden")
      ) {
        ScholarshipStrings.t(.navApply, locale)
      }
      a(
        .href(prefixed("/my-application")), .class("nav-link"),
        .custom(name: "data-auth-state", value: "signed-in"),
        .custom(name: "hidden", value: "hidden")
      ) {
        ScholarshipStrings.t(.navMyApplication, locale)
      }

      // Organizer link (hidden until `/me` reports admin role).
      a(
        .href(prefixed("/organizer")), .class("nav-link"),
        .custom(name: "data-auth-state", value: "organizer"),
        .custom(name: "hidden", value: "hidden")
      ) {
        ScholarshipStrings.t(.navOrganizer, locale)
      }

      // Logout button — JS handles the API call so the bare `<form>` works
      // even before scholarship.js loads.
      button(
        .type(.button),
        .id("nav-logout-button"),
        .custom(name: "data-auth-state", value: "signed-in"),
        .custom(name: "hidden", value: "hidden")
      ) {
        ScholarshipStrings.t(.navLogout, locale)
      }
    }
  }

  private var rootHref: String {
    locale == .ja ? "/ja" : "/"
  }

  private func prefixed(_ path: String) -> String {
    locale == .ja ? "/ja\(path)" : path
  }
}
