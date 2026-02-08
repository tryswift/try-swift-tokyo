import Testing
import Vapor
import VaporTesting

@testable import Server

@Suite("CSRFMiddleware Tests")
struct CSRFMiddlewareTests {

  /// Helper: create an Application with CSRFMiddleware and simple test routes
  private func makeApp() async throws -> Application {
    let app = try await Application.make(.testing)

    let csrf = app.grouped(CSRFMiddleware())
    csrf.get("page") { _ in "OK" }
    csrf.post("action") { _ in "Done" }

    return app
  }

  // MARK: - GET Requests

  @Test("GET request without csrf_token cookie sets one")
  func getSetsCookie() async throws {
    let app = try await makeApp()
    do {
      try await app.testing().test(.GET, "page") { response in
        #expect(response.status == .ok)

        let csrfCookie = response.headers.setCookie?["csrf_token"]
        #expect(csrfCookie != nil)
        #expect(csrfCookie?.string.isEmpty == false)
        #expect(csrfCookie?.sameSite == .strict)
        #expect(csrfCookie?.isHTTPOnly == false)
        #expect(csrfCookie?.path == "/")
      }
    } catch {
      try await app.asyncShutdown()
      throw error
    }
    try await app.asyncShutdown()
  }

  @Test("GET request with existing valid hex csrf_token cookie does not overwrite it")
  func getPreservesExistingCookie() async throws {
    let app = try await makeApp()
    do {
      let validHexToken = String(repeating: "ab", count: 32)  // 64 hex chars
      try await app.testing().test(
        .GET, "page",
        beforeRequest: { req in
          req.headers.cookie = HTTPCookies(
            dictionaryLiteral: ("csrf_token", .init(string: validHexToken)))
        }
      ) { response in
        #expect(response.status == .ok)

        // Should not set a new cookie since a valid hex token already exists
        let setCookieHeader = response.headers.setCookie
        let csrfCookie = setCookieHeader?["csrf_token"]
        #expect(csrfCookie == nil)
      }
    } catch {
      try await app.asyncShutdown()
      throw error
    }
    try await app.asyncShutdown()
  }

  @Test("GET request with legacy base64 csrf_token cookie regenerates it")
  func getRegeneratesLegacyBase64Cookie() async throws {
    let app = try await makeApp()
    do {
      // Simulate a legacy base64 token containing +, /, =
      let legacyBase64Token = "abc+def/ghi12345678901234567890=="
      try await app.testing().test(
        .GET, "page",
        beforeRequest: { req in
          req.headers.cookie = HTTPCookies(
            dictionaryLiteral: ("csrf_token", .init(string: legacyBase64Token)))
        }
      ) { response in
        #expect(response.status == .ok)

        // Should regenerate cookie since existing one is not valid hex
        let csrfCookie = response.headers.setCookie?["csrf_token"]
        #expect(csrfCookie != nil)
        let newToken = csrfCookie?.string ?? ""
        #expect(newToken.count == 64)
        let hexCharSet = CharacterSet(charactersIn: "0123456789abcdef")
        #expect(newToken.unicodeScalars.allSatisfy { hexCharSet.contains($0) })
      }
    } catch {
      try await app.asyncShutdown()
      throw error
    }
    try await app.asyncShutdown()
  }

  // MARK: - POST Requests without CSRF token

  @Test("POST without csrf_token cookie returns 403")
  func postWithoutCookieReturns403() async throws {
    let app = try await makeApp()
    do {
      try await app.testing().test(.POST, "action") { response in
        #expect(response.status == .forbidden)
      }
    } catch {
      try await app.asyncShutdown()
      throw error
    }
    try await app.asyncShutdown()
  }

  @Test("POST with csrf_token cookie but no form field or header returns 403")
  func postWithCookieButNoTokenReturns403() async throws {
    let app = try await makeApp()
    do {
      try await app.testing().test(
        .POST, "action",
        beforeRequest: { req in
          req.headers.cookie = HTTPCookies(
            dictionaryLiteral: ("csrf_token", .init(string: "test-token")))
        }
      ) { response in
        #expect(response.status == .forbidden)
      }
    } catch {
      try await app.asyncShutdown()
      throw error
    }
    try await app.asyncShutdown()
  }

  @Test("POST with mismatched csrf tokens returns 403")
  func postWithMismatchedTokensReturns403() async throws {
    let app = try await makeApp()
    do {
      try await app.testing().test(
        .POST, "action",
        beforeRequest: { req in
          req.headers.cookie = HTTPCookies(
            dictionaryLiteral: ("csrf_token", .init(string: "correct-token")))
          req.headers.replaceOrAdd(name: "X-CSRF-Token", value: "wrong-token")
        }
      ) { response in
        #expect(response.status == .forbidden)
      }
    } catch {
      try await app.asyncShutdown()
      throw error
    }
    try await app.asyncShutdown()
  }

  // MARK: - POST Requests with valid CSRF token

  @Test("POST with matching X-CSRF-Token header passes through")
  func postWithMatchingHeaderPasses() async throws {
    let app = try await makeApp()
    do {
      let token = "valid-csrf-token"
      try await app.testing().test(
        .POST, "action",
        beforeRequest: { req in
          req.headers.cookie = HTTPCookies(dictionaryLiteral: ("csrf_token", .init(string: token)))
          req.headers.replaceOrAdd(name: "X-CSRF-Token", value: token)
        }
      ) { response in
        #expect(response.status == .ok)
      }
    } catch {
      try await app.asyncShutdown()
      throw error
    }
    try await app.asyncShutdown()
  }

  @Test("POST with matching _csrf form field passes through")
  func postWithMatchingFormFieldPasses() async throws {
    let app = try await makeApp()
    do {
      let token = "valid-csrf-token"
      try await app.testing().test(
        .POST, "action",
        beforeRequest: { req in
          req.headers.cookie = HTTPCookies(dictionaryLiteral: ("csrf_token", .init(string: token)))
          req.headers.contentType = .urlEncodedForm
          req.body = ByteBuffer(string: "_csrf=\(token)")
        }
      ) { response in
        #expect(response.status == .ok)
      }
    } catch {
      try await app.asyncShutdown()
      throw error
    }
    try await app.asyncShutdown()
  }

  @Test("Generated CSRF token uses only hex characters (no base64 special chars)")
  func generatedTokenIsHexSafe() async throws {
    let app = try await makeApp()
    do {
      try await app.testing().test(.GET, "page") { response in
        #expect(response.status == .ok)

        let csrfCookie = response.headers.setCookie?["csrf_token"]
        let token = csrfCookie?.string ?? ""
        #expect(!token.isEmpty)
        // Token should be 64 hex chars (32 bytes × 2 hex digits each)
        #expect(token.count == 64)
        // Token must only contain hex-safe characters (no +, /, =)
        let hexCharSet = CharacterSet(charactersIn: "0123456789abcdef")
        #expect(token.unicodeScalars.allSatisfy { hexCharSet.contains($0) })
      }
    } catch {
      try await app.asyncShutdown()
      throw error
    }
    try await app.asyncShutdown()
  }

  @Test("POST form field takes precedence over header when both present")
  func postFormFieldPrecedence() async throws {
    let app = try await makeApp()
    do {
      let token = "valid-csrf-token"
      try await app.testing().test(
        .POST, "action",
        beforeRequest: { req in
          req.headers.cookie = HTTPCookies(dictionaryLiteral: ("csrf_token", .init(string: token)))
          req.headers.contentType = .urlEncodedForm
          req.body = ByteBuffer(string: "_csrf=\(token)")
          // Header has wrong value, but form field is correct
          req.headers.replaceOrAdd(name: "X-CSRF-Token", value: "wrong-token")
        }
      ) { response in
        #expect(response.status == .ok)
      }
    } catch {
      try await app.asyncShutdown()
      throw error
    }
    try await app.asyncShutdown()
  }

  // MARK: - Edge cases

  @Test("POST with empty csrf_token cookie returns 403")
  func postWithEmptyCookieReturns403() async throws {
    let app = try await makeApp()
    do {
      try await app.testing().test(
        .POST, "action",
        beforeRequest: { req in
          req.headers.cookie = HTTPCookies(dictionaryLiteral: ("csrf_token", .init(string: "")))
          req.headers.replaceOrAdd(name: "X-CSRF-Token", value: "")
        }
      ) { response in
        #expect(response.status == .forbidden)
      }
    } catch {
      try await app.asyncShutdown()
      throw error
    }
    try await app.asyncShutdown()
  }

  @Test("Non-POST methods (PUT, DELETE, PATCH) are not blocked")
  func nonPostMethodsPass() async throws {
    let app = try await Application.make(.testing)
    do {
      let csrf = app.grouped(CSRFMiddleware())
      csrf.put("update") { _ in "updated" }
      csrf.delete("remove") { _ in "removed" }
      csrf.patch("modify") { _ in "modified" }

      try await app.testing().test(.PUT, "update") { response in
        #expect(response.status == .ok)
      }
      try await app.testing().test(.DELETE, "remove") { response in
        #expect(response.status == .ok)
      }
      try await app.testing().test(.PATCH, "modify") { response in
        #expect(response.status == .ok)
      }
    } catch {
      try await app.asyncShutdown()
      throw error
    }
    try await app.asyncShutdown()
  }
}
