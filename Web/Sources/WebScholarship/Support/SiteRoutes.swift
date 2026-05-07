import Foundation
import SharedModels

/// One static page rendered by `StaticSiteBuilder`.
struct SiteRoute: Sendable {
  let path: String
  let page: ScholarshipPage
  let locale: ScholarshipPortalLocale
}

struct RewriteRule: Sendable {
  let from: String
  let to: String
}

/// Pages exposed by student.tryswift.jp. Each entry pre-renders an HTML shell;
/// auth-gated content is filled in client-side by `scripts/scholarship.js`.
enum ScholarshipPage: String, Sendable {
  case info
  case login
  case loginSent = "login-sent"
  case apply
  case myApplication = "my-application"
  case organizerList = "organizer-list"
  case organizerDetail = "organizer-detail"
  case organizerBudget = "organizer-budget"
}

enum SiteRoutes {
  static let concrete: [SiteRoute] = {
    let english: [SiteRoute] = [
      SiteRoute(path: "/", page: .info, locale: .en),
      SiteRoute(path: "/login", page: .login, locale: .en),
      SiteRoute(path: "/login/sent", page: .loginSent, locale: .en),
      SiteRoute(path: "/apply", page: .apply, locale: .en),
      SiteRoute(path: "/my-application", page: .myApplication, locale: .en),
      SiteRoute(path: "/organizer", page: .organizerList, locale: .en),
      SiteRoute(path: "/organizer/budget", page: .organizerBudget, locale: .en),
    ]
    let japanese: [SiteRoute] = [
      SiteRoute(path: "/ja", page: .info, locale: .ja),
      SiteRoute(path: "/ja/login", page: .login, locale: .ja),
      SiteRoute(path: "/ja/login/sent", page: .loginSent, locale: .ja),
      SiteRoute(path: "/ja/apply", page: .apply, locale: .ja),
      SiteRoute(path: "/ja/my-application", page: .myApplication, locale: .ja),
      SiteRoute(path: "/ja/organizer", page: .organizerList, locale: .ja),
      SiteRoute(path: "/ja/organizer/budget", page: .organizerBudget, locale: .ja),
    ]
    return english + japanese
  }()

  /// Cloudflare Pages SPA-style fallthroughs. Detail routes such as
  /// `/organizer/<uuid>` map to the shared organizer-detail shell that JS
  /// hydrates from the path param.
  static let rewriteRules: [RewriteRule] = [
    RewriteRule(from: "/organizer/:id", to: "/organizer/detail/index.html"),
    RewriteRule(from: "/ja/organizer/:id", to: "/ja/organizer/detail/index.html"),
  ]

  /// Detail-page templates that don't have a fixed path but need an HTML shell
  /// at a stable location for the rewrite rules above.
  static let detailRoutes: [SiteRoute] = [
    SiteRoute(path: "/organizer/detail", page: .organizerDetail, locale: .en),
    SiteRoute(path: "/ja/organizer/detail", page: .organizerDetail, locale: .ja),
  ]
}
