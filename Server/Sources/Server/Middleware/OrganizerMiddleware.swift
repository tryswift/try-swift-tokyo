import Vapor
import JWT
import SharedModels

/// Middleware that requires the user to be an admin (organizer)
/// Returns 403 Forbidden if the user's role is not admin
struct OrganizerMiddleware: AsyncMiddleware {
  func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
    // Extract JWT payload from request
    let payload = try await request.jwt.verify(as: UserJWTPayload.self)
    
    // Check if user is admin
    guard payload.role == .admin else {
      throw Abort(.forbidden, reason: "Only organizers can access this resource")
    }
    
    // Continue to next handler
    return try await next.respond(to: request)
  }
}
