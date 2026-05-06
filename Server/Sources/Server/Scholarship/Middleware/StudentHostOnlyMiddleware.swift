import Vapor

/// Returns 404 for non-student-host requests so api.tryswift.jp / sponsor.tryswift.jp
/// can't reach the student portal route tree even though all hosts share the
/// same Vapor application. Relies on `HostRoutingMiddleware` having set
/// `request.isStudentHost` earlier in the global middleware chain.
struct StudentHostOnlyMiddleware: AsyncMiddleware {
  func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
    guard request.isStudentHost else { throw Abort(.notFound) }
    return try await next.respond(to: request)
  }
}
