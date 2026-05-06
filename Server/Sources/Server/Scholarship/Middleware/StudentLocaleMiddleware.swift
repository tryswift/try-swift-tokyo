import SharedModels
import Vapor

/// Resolves the student-portal locale from `/ja` / `/en` URL prefixes,
/// a `student_locale` cookie, or the `Accept-Language` header. Stores the
/// result so pages and emails can render with the correct strings.
struct StudentLocaleMiddleware: AsyncMiddleware {
  static let cookieName = "student_locale"

  func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
    request.storage[StudentLocaleStorageKey.self] = resolve(request)
    return try await next.respond(to: request)
  }

  private func resolve(_ request: Request) -> ScholarshipPortalLocale {
    let path = request.url.path
    if path.hasPrefix("/ja") { return .ja }
    if path.hasPrefix("/en") { return .en }
    if let cookie = request.cookies[Self.cookieName]?.string,
      let l = ScholarshipPortalLocale(rawValue: cookie)
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

private struct StudentLocaleStorageKey: StorageKey { typealias Value = ScholarshipPortalLocale }

extension Request {
  var studentLocale: ScholarshipPortalLocale {
    storage[StudentLocaleStorageKey.self] ?? .default
  }
}
