import Vapor

/// Returns 404 when a request targets the sponsor host. Used to ensure
/// `/api/v1/...` routes are not exposed under `sponsor.tryswift.jp`.
struct NotSponsorHostMiddleware: AsyncMiddleware {
  func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
    if request.isSponsorHost { throw Abort(.notFound) }
    return try await next.respond(to: request)
  }
}
