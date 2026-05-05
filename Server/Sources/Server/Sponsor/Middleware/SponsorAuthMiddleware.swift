import Fluent
import JWT
import SharedModels
import Vapor

struct SponsorAuthMiddleware: AsyncMiddleware {
  let onMissingRedirectTo: String?

  init(onMissingRedirectTo: String? = "/login") {
    self.onMissingRedirectTo = onMissingRedirectTo
  }

  func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
    guard let raw = request.cookies[SponsorAuthCookie.name]?.string,
      let payload = try? await request.jwt.verify(raw, as: SponsorJWTPayload.self)
    else {
      if let path = onMissingRedirectTo {
        return request.redirect(to: path)
      }
      throw Abort(.unauthorized)
    }
    request.storage[SponsorJWTStorageKey.self] = payload
    if let id = payload.sponsorUserID,
      let user = try await SponsorUser.find(id, on: request.db)
    {
      request.storage[SponsorUserStorageKey.self] = user
    }
    return try await next.respond(to: request)
  }
}

private struct SponsorJWTStorageKey: StorageKey { typealias Value = SponsorJWTPayload }
private struct SponsorUserStorageKey: StorageKey { typealias Value = SponsorUser }

extension Request {
  var sponsorJWT: SponsorJWTPayload? { storage[SponsorJWTStorageKey.self] }
  var sponsorUser: SponsorUser? { storage[SponsorUserStorageKey.self] }
}
