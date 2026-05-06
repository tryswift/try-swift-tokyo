import Vapor

/// Returns 404 when a request targets the student portal host. Used to ensure
/// `/api/v1/...` routes are not exposed under `student.tryswift.jp`.
struct NotStudentHostMiddleware: AsyncMiddleware {
  func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
    if request.isStudentHost { throw Abort(.notFound) }
    return try await next.respond(to: request)
  }
}
