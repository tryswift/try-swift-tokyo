import Vapor

/// Double-Submit Cookie CSRF protection middleware.
///
/// On GET requests: ensures a `csrf_token` cookie exists (generates one if missing).
/// On POST requests: validates that the token from either form field `_csrf` or
/// header `X-CSRF-Token` matches the `csrf_token` cookie value.
struct CSRFMiddleware: AsyncMiddleware {
  func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
    if request.method == .POST {
      // Validate CSRF token on POST requests
      guard
        let rawCookieToken = request.cookies["csrf_token"]?.string,
        !rawCookieToken.isEmpty
      else {
        throw Abort(.forbidden, reason: "CSRF token missing")
      }
      let cookieToken = normalizeToken(rawCookieToken)

      // Check form field first, then header
      let formToken = (try? request.content.get(String.self, at: "_csrf")).map(normalizeToken)
      let headerToken = request.headers.first(name: "X-CSRF-Token").map(normalizeToken)
      let submittedToken = formToken ?? headerToken

      guard let submittedToken, submittedToken == cookieToken else {
        let formPrefix = formToken.map { String($0.prefix(8)) } ?? "nil"
        let headerPrefix = headerToken.map { String($0.prefix(8)) } ?? "nil"
        request.logger.warning(
          "CSRF mismatch: cookie=\(String(cookieToken.prefix(8)))… form=\(formPrefix) header=\(headerPrefix)"
        )
        throw Abort(.forbidden, reason: "CSRF token mismatch")
      }

      return try await next.respond(to: request)
    } else {
      // For non-POST requests, ensure csrf_token cookie exists and is valid hex.
      // Generate the token BEFORE the route handler runs so that
      // csrfToken(from:) can read it from the request cookie.
      let existingToken = normalizeToken(request.cookies["csrf_token"]?.string ?? "")
      var needsSetCookie = false
      if existingToken.isEmpty || !isValidHexToken(existingToken) {
        let token = generateCSRFToken()
        request.cookies["csrf_token"] = HTTPCookies.Value(string: token)
        needsSetCookie = true
      }

      let response = try await next.respond(to: request)

      if needsSetCookie, let token = request.cookies["csrf_token"]?.string {
        response.cookies["csrf_token"] = HTTPCookies.Value(
          string: token,
          expires: Date().addingTimeInterval(86400 * 7),
          maxAge: 86400 * 7,
          path: "/",
          isSecure: Environment.get("APP_ENV") == "production",
          isHTTPOnly: false,
          sameSite: .strict
        )
      }

      return response
    }
  }

  private func generateCSRFToken() -> String {
    var bytes = [UInt8](repeating: 0, count: 32)
    for i in 0..<32 {
      bytes[i] = UInt8.random(in: 0...255)
    }
    return bytes.map { String(format: "%02x", $0) }.joined()
  }

  private func isValidHexToken(_ token: String) -> Bool {
    token.count == 64 && token.allSatisfy { $0.isHexDigit }
  }

  private func normalizeToken(_ token: String) -> String {
    let trimmed = token.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmed.first == "\"", trimmed.last == "\"", trimmed.count >= 2 {
      return String(trimmed.dropFirst().dropLast())
    }
    return trimmed
  }
}
