import Fluent
import JWT
import SharedModels
import Vapor

/// Requires a valid `student_auth_token` cookie and exposes the resolved
/// `StudentUser` / JWT payload via `request.studentUser` / `request.studentJWT`.
///
/// When the cookie is missing or invalid the middleware redirects browsers to
/// `/login` (or the configured fallback) so the public flow can offer a magic
/// link. API-style callers should set `onMissingRedirectTo: nil` to receive a
/// 401 instead.
struct StudentAuthMiddleware: AsyncMiddleware {
  let onMissingRedirectTo: String?

  init(onMissingRedirectTo: String? = "/login") {
    self.onMissingRedirectTo = onMissingRedirectTo
  }

  func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
    guard let raw = request.cookies[StudentAuthCookie.name]?.string,
      let payload = try? await request.jwt.verify(raw, as: StudentJWTPayload.self)
    else {
      if let path = onMissingRedirectTo {
        return request.redirect(to: path)
      }
      throw Abort(.unauthorized)
    }
    request.storage[StudentJWTStorageKey.self] = payload
    if let id = payload.studentUserID,
      let user = try await StudentUser.find(id, on: request.db)
    {
      request.storage[StudentUserStorageKey.self] = user
    }
    return try await next.respond(to: request)
  }
}

private struct StudentJWTStorageKey: StorageKey { typealias Value = StudentJWTPayload }
private struct StudentUserStorageKey: StorageKey { typealias Value = StudentUser }

extension Request {
  var studentJWT: StudentJWTPayload? { storage[StudentJWTStorageKey.self] }
  var studentUser: StudentUser? { storage[StudentUserStorageKey.self] }
}
