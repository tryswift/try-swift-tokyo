import Elementary
import Fluent
import SharedModels
import Vapor
import WebSponsor

/// Lists active SponsorPlan rows for the currently-accepting Conference.
/// Mounted under the authenticated sponsor route group: requiring login here
/// is for parity with the rest of the sponsor portal UX (and to discourage
/// scraping of pricing) — the plan data itself is not sensitive.
struct SponsorPlansController: RouteCollection {
  func boot(routes: RoutesBuilder) throws {
    routes.get("plans", use: list)
  }

  func list(_ req: Request) async throws -> Response {
    guard
      let conference = try await Conference.query(on: req.db)
        .filter(\.$isAcceptingSponsors == true)
        .sort(\.$year, .descending)
        .first()
    else {
      throw Abort(.serviceUnavailable, reason: "No conference is accepting sponsors")
    }
    let plans = try await SponsorPlan.query(on: req.db)
      .filter(\.$conference.$id == (try conference.requireID()))
      .filter(\.$isActive == true)
      .sort(\.$sortOrder, .ascending)
      .with(\.$localizations)
      .all()
    let dtos = try plans.map { try $0.toDTO() }

    let html = PlansPage(locale: req.sponsorLocale, csrfToken: req.csrfToken, plans: dtos).render()
    var headers = HTTPHeaders()
    headers.contentType = .html
    return Response(status: .ok, headers: headers, body: .init(string: html))
  }
}
