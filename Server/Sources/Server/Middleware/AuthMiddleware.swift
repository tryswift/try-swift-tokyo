import JWT
import Vapor

/// Middleware that requires a valid JWT token
/// Extracts user information from JWT and stores in request
struct AuthMiddleware: AsyncMiddleware {
  func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
    // Verify JWT token and store payload for downstream handlers
    let payload = try await request.jwt.verify(as: UserJWTPayload.self)
    request.auth.login(payload)

    // Continue to next handler
    return try await next.respond(to: request)
  }
}

extension UserJWTPayload: Authenticatable {}
