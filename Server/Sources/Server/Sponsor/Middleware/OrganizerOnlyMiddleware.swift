import JWT
import SharedModels
import Vapor

struct OrganizerOnlyMiddleware: AsyncMiddleware {
  func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
    guard let raw = request.cookies["auth_token"]?.string,
      let payload = try? await request.jwt.verify(raw, as: UserJWTPayload.self)
    else {
      return request.redirect(to: organizerLoginURL())
    }
    guard payload.role == .admin else { throw Abort(.forbidden) }
    request.storage[OrganizerJWTStorageKey.self] = payload
    return try await next.respond(to: request)
  }

  private func organizerLoginURL() -> String {
    Environment.get("CFP_LOGIN_URL") ?? "https://cfp.tryswift.jp/login"
  }
}

private struct OrganizerJWTStorageKey: StorageKey { typealias Value = UserJWTPayload }

extension Request {
  var organizerJWT: UserJWTPayload? { storage[OrganizerJWTStorageKey.self] }
}
