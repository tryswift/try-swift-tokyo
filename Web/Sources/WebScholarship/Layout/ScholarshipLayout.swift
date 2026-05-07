import Elementary
import SharedModels

/// Top-level layout for student.tryswift.jp pages.
///
/// All Scholarship pages are rendered to static HTML at build time and
/// hosted on Cloudflare Pages. Dynamic behavior (auth state, fetching the
/// applicant's own application, organizer tables) lives in
/// `/student/scholarship.js`, which reads the API base URL from the meta
/// tag this layout emits.
public struct ScholarshipLayout<Inner: HTML>: HTML {
  public let pageTitle: String
  public let locale: ScholarshipPortalLocale
  public let apiBaseURL: String
  public let pageKind: String
  public let inner: Inner

  public init(
    pageTitle: String,
    locale: ScholarshipPortalLocale,
    apiBaseURL: String,
    pageKind: String,
    @HTMLBuilder inner: () -> Inner
  ) {
    self.pageTitle = pageTitle
    self.locale = locale
    self.apiBaseURL = apiBaseURL
    self.pageKind = pageKind
    self.inner = inner()
  }

  public var body: some HTML {
    HTMLRaw("<!DOCTYPE html>")
    html(.lang(locale.htmlLangCode)) {
      head {
        meta(.charset(.utf8))
        meta(.name(.viewport), .content("width=device-width, initial-scale=1"))
        title { "\(pageTitle) | try! Swift Tokyo Scholarship" }
        meta(
          .custom(name: "name", value: "scholarship-api-base-url"), .content(apiBaseURL))
        meta(
          .custom(name: "name", value: "scholarship-locale"), .content(locale.rawValue))
        link(.rel(.stylesheet), .href("/student/student.css"))
        script(.src("/student/scholarship.js"), .custom(name: "defer", value: "defer")) {}
      }
      Elementary.body(.custom(name: "data-page", value: pageKind)) {
        ScholarshipNav(locale: locale)
        div(.id("flash"), .class("flash hidden")) {}
        main(.class("portal-main")) { inner }
      }
    }
  }
}
