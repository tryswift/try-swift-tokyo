import JWT
import Vapor

/// Middleware that requires a valid JWT token
/// Extracts user information from JWT and stores in request
struct AuthMiddleware: AsyncMiddleware {
  func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
    _ = try await request.requireAuthenticatedUserPayload()

    // Continue to next handler
    return try await next.respond(to: request)
  }
}

extension UserJWTPayload: Authenticatable {}
