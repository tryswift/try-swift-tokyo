import Vapor

/// Aggregates all sponsor.tryswift.jp routes.
///
/// Public, sponsor-authenticated, and organizer routes share a host filter
/// (`SponsorHostOnlyMiddleware`) so requests targeting any other host (api.tryswift.jp,
/// cfp.tryswift.jp) cannot reach this tree. Locale resolution is shared.
struct SponsorRoutes: RouteCollection {
  func boot(routes: RoutesBuilder) throws {
    let sponsorOnly = routes.grouped(SponsorHostOnlyMiddleware())
      .grouped(LocaleMiddleware())
      .grouped(CSRFMiddleware())

    try sponsorOnly.register(collection: SponsorPublicController())

    let auth = sponsorOnly.grouped(SponsorAuthMiddleware())
    try auth.register(collection: SponsorPortalController())
    try auth.register(collection: SponsorPlansController())
    try auth.register(collection: SponsorApplicationController())

    let admin = sponsorOnly.grouped(OrganizerOnlyMiddleware())
    try admin.register(collection: OrganizerSponsorController())
  }
}

/// Returns 404 for non-sponsor host requests so api.tryswift.jp can't reach Sponsor routes.
struct SponsorHostOnlyMiddleware: AsyncMiddleware {
  func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
    guard request.isSponsorHost else { throw Abort(.notFound) }
    return try await next.respond(to: request)
  }
}
