import Vapor

/// Returns 404 for non-sponsor host requests so api.tryswift.jp / cfp.tryswift.jp
/// can't reach the sponsor portal route tree even though the routes share the
/// same Vapor application. Relies on `HostRoutingMiddleware` having set
/// `request.isSponsorHost` earlier in the global middleware chain.
struct SponsorHostOnlyMiddleware: AsyncMiddleware {
  func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
    guard request.isSponsorHost else { throw Abort(.notFound) }
    return try await next.respond(to: request)
  }
}
