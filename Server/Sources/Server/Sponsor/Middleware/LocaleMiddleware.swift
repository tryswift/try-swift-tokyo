import SharedModels
import Vapor

struct LocaleMiddleware: AsyncMiddleware {
  static let cookieName = "sponsor_locale"

  func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
    request.storage[SponsorLocaleStorageKey.self] = resolve(request)
    return try await next.respond(to: request)
  }

  private func resolve(_ request: Request) -> SponsorPortalLocale {
    let path = request.url.path
    if path.hasPrefix("/ja") { return .ja }
    if path.hasPrefix("/en") { return .en }
    if let cookie = request.cookies[Self.cookieName]?.string,
      let l = SponsorPortalLocale(rawValue: cookie)
    {
      return l
    }
    if let header = request.headers.first(name: .acceptLanguage)?.lowercased() {
      if header.hasPrefix("en") { return .en }
      if header.hasPrefix("ja") { return .ja }
    }
    return .default
  }
}

private struct SponsorLocaleStorageKey: StorageKey { typealias Value = SponsorPortalLocale }

extension Request {
  var sponsorLocale: SponsorPortalLocale {
    storage[SponsorLocaleStorageKey.self] ?? .default
  }
}
