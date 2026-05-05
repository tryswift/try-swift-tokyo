import Foundation
import SharedModels
import Testing
import Vapor
import VaporTesting

@testable import Server

@Suite("LocaleMiddleware")
struct LocaleMiddlewareTests {
  @Test("URL prefix /ja wins over Accept-Language: en")
  func prefixWins() async throws {
    let app = try await Application.make(.testing)
    defer { Task { try? await app.asyncShutdown() } }
    app.middleware.use(LocaleMiddleware())
    app.get("ja", "x") { req in req.sponsorLocale.rawValue }
    try await app.testing().test(
      .GET, "ja/x",
      beforeRequest: { req in req.headers.replaceOrAdd(name: .acceptLanguage, value: "en-US") }
    ) { res in
      #expect(res.body.string == "ja")
    }
  }

  @Test("Accept-Language used if no prefix or cookie")
  func acceptLanguage() async throws {
    let app = try await Application.make(.testing)
    defer { Task { try? await app.asyncShutdown() } }
    app.middleware.use(LocaleMiddleware())
    app.get("x") { req in req.sponsorLocale.rawValue }
    try await app.testing().test(
      .GET, "x",
      beforeRequest: { req in req.headers.replaceOrAdd(name: .acceptLanguage, value: "en") }
    ) { res in #expect(res.body.string == "en") }
  }
}
