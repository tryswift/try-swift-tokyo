import Vapor
import JWT

/// Middleware that requires a valid JWT token
/// Extracts user information from JWT and stores in request
struct AuthMiddleware: AsyncMiddleware {
  func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
    // Verify JWT token
    _ = try await request.jwt.verify(as: UserJWTPayload.self)

    // Continue to next handler
    return try await next.respond(to: request)
  }
}
