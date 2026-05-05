import Foundation
import Vapor

enum SponsorAuthCookie {
  static let name = "sponsor_auth_token"

  static func cookieDomain() -> String? {
    if let host = Environment.get("SPONSOR_BASE_URL").flatMap(URL.init(string:))?.host {
      let parts = host.split(separator: ".")
      if parts.count >= 2 { return "." + parts.suffix(2).joined(separator: ".") }
      return host
    }
    return nil
  }

  static func make(value token: String, ttl: TimeInterval = 86400 * 30) -> HTTPCookies.Value {
    let isSecure = Environment.get("APP_ENV") == "production"
    return HTTPCookies.Value(
      string: token,
      expires: Date().addingTimeInterval(ttl),
      maxAge: Int(ttl),
      domain: cookieDomain(),
      path: "/",
      isSecure: isSecure,
      isHTTPOnly: true,
      sameSite: .lax
    )
  }
}
