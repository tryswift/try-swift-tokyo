import Foundation

struct SiteRoute: Sendable {
  let path: String
  let page: SponsorPage
}

struct RewriteRule: Sendable {
  let from: String
  let to: String
}

enum SiteRoutes {
  // Phase 2 ships only the public-facing pages. Sponsor portal and organizer
  // dashboards still SSR from the Vapor app and will move to static + JSON
  // API in a follow-up PR.
  static let concrete: [SiteRoute] = {
    let english: [SiteRoute] = [
      SiteRoute(path: "/", page: .inquiry(.en)),
      SiteRoute(path: "/inquiry", page: .inquiry(.en)),
      SiteRoute(path: "/inquiry/thanks", page: .inquiryThanks(.en)),
      SiteRoute(path: "/login", page: .loginRequest(.en)),
      SiteRoute(path: "/login/sent", page: .loginSent(.en)),
    ]

    let japanese: [SiteRoute] = [
      SiteRoute(path: "/ja", page: .inquiry(.ja)),
      SiteRoute(path: "/ja/inquiry", page: .inquiry(.ja)),
      SiteRoute(path: "/ja/inquiry/thanks", page: .inquiryThanks(.ja)),
      SiteRoute(path: "/ja/login", page: .loginRequest(.ja)),
      SiteRoute(path: "/ja/login/sent", page: .loginSent(.ja)),
    ]

    return english + japanese
  }()

  static let rewriteRules: [RewriteRule] = []
}
