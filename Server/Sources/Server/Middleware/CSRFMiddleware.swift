import Vapor

/// Double-Submit Cookie CSRF protection middleware.
///
/// On GET requests: ensures a `csrf_token` cookie exists (generates one if missing).
/// On POST requests: validates that the token from either form field `_csrf` or
/// header `X-CSRF-Token` matches the `csrf_token` cookie value.
struct CSRFMiddleware: AsyncMiddleware {
  private static let maxCSRFCookieTokens = 32
  private static let maxCSRFBodyScanBytes = 64 * 1024

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
    var seenTokens = Set<String>()

    if let parsedCookieToken = request.cookies["csrf_token"]?.string {
      let normalized = normalizeToken(parsedCookieToken)
      if !normalized.isEmpty, seenTokens.insert(normalized).inserted {
        tokens.append(normalized)
      }
    }

    cookieHeaders: for cookieHeader in request.headers[.cookie] {
      let pairs = cookieHeader.split(separator: ";")
      for pair in pairs {
        if tokens.count >= Self.maxCSRFCookieTokens {
          break cookieHeaders
        }
        let trimmed = pair.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasPrefix("csrf_token=") else { continue }
        let rawValue = String(trimmed.dropFirst("csrf_token=".count))
        let decodedValue = rawValue.removingPercentEncoding ?? rawValue
        let normalized = normalizeToken(decodedValue)
        if !normalized.isEmpty, seenTokens.insert(normalized).inserted {
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

    guard let body = request.body.data, body.readableBytes > 0 else {
      return nil
    }
    let scanBytes = min(body.readableBytes, Self.maxCSRFBodyScanBytes)
    guard let rawBody = body.getBytes(at: body.readerIndex, length: scanBytes), !rawBody.isEmpty
    else {
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

  private func extractURLFormCSRF(from rawBody: [UInt8]) -> String? {
    let ampersand: UInt8 = 38  // &
    let equals: UInt8 = 61  // =
    let csrfKey = Array("_csrf".utf8)

    var pairStart = 0
    while pairStart < rawBody.count {
      var pairEnd = pairStart
      while pairEnd < rawBody.count, rawBody[pairEnd] != ampersand {
        pairEnd += 1
      }

      var split = pairStart
      while split < pairEnd, rawBody[split] != equals {
        split += 1
      }

      if split < pairEnd {
        let key = rawBody[pairStart..<split]
        if key.elementsEqual(csrfKey) {
          let value = Array(rawBody[(split + 1)..<pairEnd])
          return decodeURLFormValue(value)
        }
      }

      pairStart = pairEnd + 1
    }

    return nil
  }

  private func extractMultipartCSRF(from rawBody: [UInt8]) -> String? {
    let csrfFieldMarker = Array("name=\"_csrf\"".utf8)
    guard let markerIndex = firstIndex(of: csrfFieldMarker, in: rawBody) else { return nil }

    let afterMarker = markerIndex + csrfFieldMarker.count
    if let valueStart = firstIndex(of: [13, 10, 13, 10], in: rawBody, from: afterMarker) {
      return extractMultipartValue(from: rawBody, valueStart: valueStart + 4)
    }
    if let valueStart = firstIndex(of: [10, 10], in: rawBody, from: afterMarker) {
      return extractMultipartValue(from: rawBody, valueStart: valueStart + 2)
    }

    return nil
  }

  private func extractMultipartValue(from rawBody: [UInt8], valueStart: Int) -> String? {
    guard valueStart < rawBody.count else { return nil }

    var valueEnd = valueStart
    while valueEnd < rawBody.count, rawBody[valueEnd] != 10, rawBody[valueEnd] != 13 {
      valueEnd += 1
    }

    guard valueEnd > valueStart else { return nil }
    let valueBytes = Array(rawBody[valueStart..<valueEnd])
    let normalized = normalizeToken(String(decoding: valueBytes, as: UTF8.self))
    return normalized.isEmpty ? nil : normalized
  }

  private func decodeURLFormValue(_ encodedValue: [UInt8]) -> String? {
    var decoded: [UInt8] = []
    decoded.reserveCapacity(encodedValue.count)

    var index = 0
    while index < encodedValue.count {
      let byte = encodedValue[index]

      if byte == 43 {  // +
        decoded.append(32)
        index += 1
        continue
      }

      if byte == 37, index + 2 < encodedValue.count,  // %
        let high = hexNibble(encodedValue[index + 1]),
        let low = hexNibble(encodedValue[index + 2])
      {
        decoded.append((high << 4) | low)
        index += 3
        continue
      }

      decoded.append(byte)
      index += 1
    }

    let normalized = normalizeToken(String(decoding: decoded, as: UTF8.self))
    return normalized.isEmpty ? nil : normalized
  }

  private func hexNibble(_ byte: UInt8) -> UInt8? {
    switch byte {
    case 48...57:  // 0-9
      return byte - 48
    case 65...70:  // A-F
      return byte - 55
    case 97...102:  // a-f
      return byte - 87
    default:
      return nil
    }
  }

  private func firstIndex(of needle: [UInt8], in haystack: [UInt8], from start: Int = 0) -> Int? {
    guard !needle.isEmpty, haystack.count >= needle.count, start >= 0 else { return nil }
    guard start <= haystack.count - needle.count else { return nil }

    let lastStart = haystack.count - needle.count
    for index in start...lastStart {
      if haystack[index..<(index + needle.count)].elementsEqual(needle) {
        return index
      }
    }
    return nil
  }
}
