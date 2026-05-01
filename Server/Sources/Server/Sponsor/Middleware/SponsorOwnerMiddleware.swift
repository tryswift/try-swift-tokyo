import Fluent
import SharedModels
import Vapor

/// Requires that the authenticated sponsor user has the `.owner` role on their JWT-attached organisation.
struct SponsorOwnerMiddleware: AsyncMiddleware {
  func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
    guard let payload = request.sponsorJWT, payload.role == .owner else {
      throw Abort(.forbidden)
    }
    return try await next.respond(to: request)
  }
}
