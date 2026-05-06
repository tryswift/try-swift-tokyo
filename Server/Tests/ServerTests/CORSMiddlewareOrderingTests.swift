import Testing
import Vapor
import VaporTesting

/// Regression tests for CORS header propagation on error responses.
///
/// Vapor auto-registers `ErrorMiddleware` at the front of the middleware chain.
/// Appending `CORSMiddleware` via `app.middleware.use(_:)` (which defaults to
/// `.end`) places CORS *inside* ErrorMiddleware — so when an inner middleware
/// throws an `Abort`, the resulting Response is produced by ErrorMiddleware and
/// never decorated with CORS headers. The browser then misreports the failure
/// as a CORS error rather than the underlying status (401/403/404).
///
/// Production must register CORS with `at: .beginning` so it sits *outside*
/// ErrorMiddleware and decorates every Response, including error ones.
@Suite("CORSMiddleware ordering")
struct CORSMiddlewareOrderingTests {
  private static let allowedOrigin = "https://cfp.tryswift.jp"

  private static func corsConfiguration() -> CORSMiddleware.Configuration {
    CORSMiddleware.Configuration(
      allowedOrigin: .originBased,
      allowedMethods: [.GET, .POST, .PUT, .DELETE, .OPTIONS],
      allowedHeaders: [.accept, .authorization, .contentType, .origin, .xRequestedWith],
      allowCredentials: true
    )
  }

  @Test("CORS at .beginning decorates 404 error responses")
  func corsAtBeginningCovers404() async throws {
    let app = try await Application.make(.testing)
    do {
      app.middleware.use(CORSMiddleware(configuration: Self.corsConfiguration()), at: .beginning)
      app.get("known") { _ in "ok" }

      try await app.testing().test(
        .GET, "unknown-route",
        beforeRequest: { req in req.headers.replaceOrAdd(name: .origin, value: Self.allowedOrigin) }
      ) { res in
        #expect(res.status == .notFound)
        #expect(res.headers.first(name: "access-control-allow-origin") == Self.allowedOrigin)
      }
    } catch {
      try await app.asyncShutdown()
      throw error
    }
    try await app.asyncShutdown()
  }

  @Test("CORS at .beginning decorates thrown Abort(.unauthorized) responses")
  func corsAtBeginningCovers401() async throws {
    let app = try await Application.make(.testing)
    do {
      app.middleware.use(CORSMiddleware(configuration: Self.corsConfiguration()), at: .beginning)
      app.get("needs-auth") { _ -> String in
        throw Abort(.unauthorized, reason: "Authentication required")
      }

      try await app.testing().test(
        .GET, "needs-auth",
        beforeRequest: { req in req.headers.replaceOrAdd(name: .origin, value: Self.allowedOrigin) }
      ) { res in
        #expect(res.status == .unauthorized)
        #expect(res.headers.first(name: "access-control-allow-origin") == Self.allowedOrigin)
      }
    } catch {
      try await app.asyncShutdown()
      throw error
    }
    try await app.asyncShutdown()
  }

  @Test("CORS at .beginning still answers preflight OPTIONS")
  func corsAtBeginningHandlesPreflight() async throws {
    let app = try await Application.make(.testing)
    do {
      app.middleware.use(CORSMiddleware(configuration: Self.corsConfiguration()), at: .beginning)

      try await app.testing().test(
        .OPTIONS, "anything",
        beforeRequest: { req in
          req.headers.replaceOrAdd(name: .origin, value: Self.allowedOrigin)
          req.headers.replaceOrAdd(name: "Access-Control-Request-Method", value: "GET")
        }
      ) { res in
        // Without `res.status == .ok`, this test would still pass if CORSMiddleware
        // ever stopped short-circuiting OPTIONS — the request would fall through to
        // a 404 that, post-fix, also carries the allow-origin header. Asserting both
        // status and allow-methods locks in *preflight handling*, not just header
        // decoration.
        #expect(res.status == .ok)
        #expect(res.headers.first(name: "access-control-allow-origin") == Self.allowedOrigin)
        let allowedMethods = res.headers.first(name: "access-control-allow-methods") ?? ""
        #expect(allowedMethods.contains("GET"))
      }
    } catch {
      try await app.asyncShutdown()
      throw error
    }
    try await app.asyncShutdown()
  }

  @Test("Default .end placement leaves error responses without CORS headers")
  func defaultEndPlacementOmitsCORSOnErrors() async throws {
    let app = try await Application.make(.testing)
    do {
      // Mirrors the *previous* (broken) registration to lock in the regression
      // we just fixed. If Vapor changes ErrorMiddleware semantics so that the
      // default placement starts decorating error responses, this assertion
      // will flip and the production wiring can be reconsidered.
      app.middleware.use(CORSMiddleware(configuration: Self.corsConfiguration()))

      try await app.testing().test(
        .GET, "missing",
        beforeRequest: { req in req.headers.replaceOrAdd(name: .origin, value: Self.allowedOrigin) }
      ) { res in
        #expect(res.status == .notFound)
        #expect(res.headers.first(name: "access-control-allow-origin") == nil)
      }
    } catch {
      try await app.asyncShutdown()
      throw error
    }
    try await app.asyncShutdown()
  }
}
