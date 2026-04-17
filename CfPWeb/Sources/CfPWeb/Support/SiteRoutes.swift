import Foundation

struct SiteRoute: Sendable {
  let path: String
  let page: CfPPage
}

struct RewriteRule: Sendable {
  let from: String
  let to: String
}

enum SiteRoutes {
  static let concrete: [SiteRoute] = {
    let english: [SiteRoute] = [
      SiteRoute(path: "/", page: .home),
      SiteRoute(path: "/guidelines", page: .guidelines),
      SiteRoute(path: "/login", page: .login),
      SiteRoute(path: "/login-page", page: .login),
      SiteRoute(path: "/profile", page: .profile),
      SiteRoute(path: "/submit", page: .submit),
      SiteRoute(path: "/submit-page", page: .submit),
      SiteRoute(path: "/workshops", page: .workshops),
      SiteRoute(path: "/workshops/apply", page: .workshops),
      SiteRoute(path: "/workshops/status", page: .workshops),
      SiteRoute(path: "/my-proposals", page: .myProposals),
      SiteRoute(path: "/my-proposals-page", page: .myProposals),
      SiteRoute(path: "/feedback", page: .feedback),
      SiteRoute(path: "/organizer", page: .organizer),
      SiteRoute(path: "/organizer/proposals", page: .organizer),
      SiteRoute(path: "/organizer/proposals/new", page: .organizer),
      SiteRoute(path: "/organizer/proposals/import", page: .organizer),
      SiteRoute(path: "/organizer/timetable", page: .organizer),
      SiteRoute(path: "/organizer/workshops", page: .organizer),
      SiteRoute(path: "/organizer/workshops/applications", page: .organizer),
      SiteRoute(path: "/organizer/workshops/results", page: .organizer),
    ]

    let japanese: [SiteRoute] = [
      SiteRoute(path: "/ja", page: .home),
      SiteRoute(path: "/ja/guidelines", page: .guidelines),
      SiteRoute(path: "/ja/login", page: .login),
      SiteRoute(path: "/ja/profile", page: .profile),
      SiteRoute(path: "/ja/submit", page: .submit),
      SiteRoute(path: "/ja/workshops", page: .workshops),
      SiteRoute(path: "/ja/workshops/apply", page: .workshops),
      SiteRoute(path: "/ja/workshops/status", page: .workshops),
      SiteRoute(path: "/ja/my-proposals", page: .myProposals),
      SiteRoute(path: "/ja/feedback", page: .feedback),
      SiteRoute(path: "/ja/organizer/proposals", page: .organizer),
      SiteRoute(path: "/ja/organizer/proposals/new", page: .organizer),
      SiteRoute(path: "/ja/organizer/proposals/import", page: .organizer),
      SiteRoute(path: "/ja/organizer/timetable", page: .organizer),
      SiteRoute(path: "/ja/organizer/workshops", page: .organizer),
      SiteRoute(path: "/ja/organizer/workshops/applications", page: .organizer),
      SiteRoute(path: "/ja/organizer/workshops/results", page: .organizer),
    ]

    let legacyCFP = english.map { route in
      SiteRoute(path: "/cfp" + (route.path == "/" ? "" : route.path), page: route.page)
    }

    return english + japanese + legacyCFP
  }()

  static let rewriteRules: [RewriteRule] = [
    RewriteRule(from: "/cfp", to: "/"),
    RewriteRule(from: "/cfp/*", to: "/:splat"),
    RewriteRule(from: "/organizer/*", to: "/organizer/index.html"),
    RewriteRule(from: "/my-proposals/*", to: "/my-proposals/index.html"),
    RewriteRule(from: "/workshops/*", to: "/workshops/index.html"),
    RewriteRule(from: "/ja/organizer/*", to: "/ja/organizer/proposals/index.html"),
    RewriteRule(from: "/ja/my-proposals/*", to: "/ja/my-proposals/index.html"),
    RewriteRule(from: "/ja/workshops/*", to: "/ja/workshops/index.html"),
  ]
}
