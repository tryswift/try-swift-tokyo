import JWT
import SharedModels
import Vapor

struct OrganizerOnlyMiddleware: AsyncMiddleware {
  /// What to do when the request lacks a valid `auth_token` cookie.
  /// SSR routes redirect to the cfp login page so the user can sign in;
  /// JSON API routes (Cloudflare Pages clients) want a 401 instead so a
  /// browser `fetch` can surface a proper error instead of landing on
  /// an HTML page.
  enum UnauthenticatedAction: Sendable {
    case redirectToCfPLogin
    case abortUnauthorized
  }

  let unauthenticatedAction: UnauthenticatedAction

  init(unauthenticatedAction: UnauthenticatedAction = .redirectToCfPLogin) {
    self.unauthenticatedAction = unauthenticatedAction
  }

  func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
    guard let raw = request.cookies["auth_token"]?.string,
      let payload = try? await request.jwt.verify(raw, as: UserJWTPayload.self)
    else {
      switch unauthenticatedAction {
      case .redirectToCfPLogin:
        return request.redirect(to: organizerLoginURL())
      case .abortUnauthorized:
        throw Abort(.unauthorized)
      }
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
