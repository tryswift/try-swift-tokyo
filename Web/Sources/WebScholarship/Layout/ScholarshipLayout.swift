import Elementary
import SharedModels

public struct ScholarshipLayout<Inner: HTML>: HTML {
  public let pageTitle: String
  public let locale: ScholarshipPortalLocale
  public let isAuthenticated: Bool
  public let isOrganizer: Bool
  public let flash: String?
  public let csrfToken: String
  public let inner: Inner

  public init(
    pageTitle: String,
    locale: ScholarshipPortalLocale,
    isAuthenticated: Bool,
    isOrganizer: Bool = false,
    flash: String? = nil,
    csrfToken: String = "",
    @HTMLBuilder inner: () -> Inner
  ) {
    self.pageTitle = pageTitle
    self.locale = locale
    self.isAuthenticated = isAuthenticated
    self.isOrganizer = isOrganizer
    self.flash = flash
    self.csrfToken = csrfToken
    self.inner = inner()
  }

  public var body: some HTML {
    HTMLRaw("<!DOCTYPE html>")
    html(.lang(locale.htmlLangCode)) {
      head {
        meta(.charset(.utf8))
        meta(.name(.viewport), .content("width=device-width, initial-scale=1"))
        title { "\(pageTitle) | try! Swift Tokyo Scholarship" }
        link(.rel(.stylesheet), .href("/student/student.css"))
      }
      Elementary.body {
        ScholarshipNav(
          locale: locale,
          isAuthenticated: isAuthenticated,
          isOrganizer: isOrganizer,
          csrfToken: csrfToken
        )
        if let flash {
          div(.class("flash")) { flash }
        }
        main(.class("portal-main")) { inner }
      }
    }
  }
}
