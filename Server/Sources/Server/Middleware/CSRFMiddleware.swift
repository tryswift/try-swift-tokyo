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
      let cookieTokens = extractCSRFCookieTokens(from: request)
      guard !cookieTokens.isEmpty else {
        throw Abort(.forbidden, reason: "CSRF token missing")
      }

      // Check form field first, then header
      let formToken = extractCSRFTokenFromForm(request).map(normalizeToken)
      let headerToken = request.headers.first(name: "X-CSRF-Token").map(normalizeToken)
      let submittedToken = formToken ?? headerToken

      guard let submittedToken, cookieTokens.contains(submittedToken) else {
        let cookiePrefixes = cookieTokens.map { String($0.prefix(8)) }.joined(separator: ",")
        let formPrefix = formToken.map { String($0.prefix(8)) } ?? "nil"
        let headerPrefix = headerToken.map { String($0.prefix(8)) } ?? "nil"
        request.logger.warning(
          "CSRF mismatch: cookies=[\(cookiePrefixes)] form=\(formPrefix) header=\(headerPrefix)"
        )
        throw Abort(.forbidden, reason: "CSRF token mismatch")
      }

      return try await next.respond(to: request)
    } else {
      // For non-POST requests, ensure csrf_token cookie exists and is valid hex.
      // Generate the token BEFORE the route handler runs so that
      // csrfToken(from:) can read it from the request cookie.
      let existingToken = extractCSRFCookieTokens(from: request).first(where: isValidHexToken) ?? ""
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

  private func extractCSRFCookieTokens(from request: Request) -> [String] {
    var tokens: [String] = []

    if let parsedCookieToken = request.cookies["csrf_token"]?.string {
      let normalized = normalizeToken(parsedCookieToken)
      if !normalized.isEmpty {
        tokens.append(normalized)
      }
    }

    for cookieHeader in request.headers[.cookie] {
      let pairs = cookieHeader.split(separator: ";")
      for pair in pairs {
        let trimmed = pair.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasPrefix("csrf_token=") else { continue }
        let rawValue = String(trimmed.dropFirst("csrf_token=".count))
        let decodedValue = rawValue.removingPercentEncoding ?? rawValue
        let normalized = normalizeToken(decodedValue)
        if !normalized.isEmpty && !tokens.contains(normalized) {
          tokens.append(normalized)
        }
      }
    }

    return tokens
  }

  private func extractCSRFTokenFromForm(_ request: Request) -> String? {
    if let decoded = try? request.content.get(String.self, at: "_csrf") {
      let normalized = normalizeToken(decoded)
      if !normalized.isEmpty {
        return normalized
      }
    }

    guard var body = request.body.data, body.readableBytes > 0 else {
      return nil
    }
    guard let rawBody = body.readString(length: body.readableBytes), !rawBody.isEmpty else {
      return nil
    }

    if let urlEncodedToken = extractURLFormCSRF(from: rawBody) {
      return urlEncodedToken
    }
    if let multipartToken = extractMultipartCSRF(from: rawBody) {
      return multipartToken
    }
    return nil
  }

  private func extractURLFormCSRF(from rawBody: String) -> String? {
    for pair in rawBody.split(separator: "&", omittingEmptySubsequences: true) {
      let parts = pair.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
      guard parts.count == 2 else { continue }
      guard parts[0] == "_csrf" else { continue }

      let value = String(parts[1]).replacingOccurrences(of: "+", with: " ")
      let decoded = value.removingPercentEncoding ?? value
      let normalized = normalizeToken(decoded)
      if !normalized.isEmpty {
        return normalized
      }
    }
    return nil
  }

  private func extractMultipartCSRF(from rawBody: String) -> String? {
    guard let nameRange = rawBody.range(of: "name=\"_csrf\"") else { return nil }
    let searchRange = nameRange.upperBound..<rawBody.endIndex

    if let separator = rawBody.range(of: "\r\n\r\n", range: searchRange) {
      let valueStart = separator.upperBound
      if let valueEnd = rawBody.range(of: "\r\n", range: valueStart..<rawBody.endIndex)?.lowerBound
      {
        let normalized = normalizeToken(String(rawBody[valueStart..<valueEnd]))
        if !normalized.isEmpty {
          return normalized
        }
      }
    }

    if let separator = rawBody.range(of: "\n\n", range: searchRange) {
      let valueStart = separator.upperBound
      if let valueEnd = rawBody.range(of: "\n", range: valueStart..<rawBody.endIndex)?.lowerBound {
        let normalized = normalizeToken(String(rawBody[valueStart..<valueEnd]))
        if !normalized.isEmpty {
          return normalized
        }
      }
    }

    return nil
  }
}
