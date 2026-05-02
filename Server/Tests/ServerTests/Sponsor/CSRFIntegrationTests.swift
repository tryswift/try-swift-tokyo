import Fluent
import Foundation
import SharedModels
import Testing
import Vapor
import VaporTesting

@testable import Server

@Suite("CSRFIntegration")
struct CSRFIntegrationTests {
  /// Reach a sponsor route via SponsorRoutes (host filter + CSRF middleware active).
  /// `Host: sponsor.tryswift.jp` is required so SponsorHostOnlyMiddleware allows the request.
  private static let sponsorHost = "sponsor.tryswift.jp"

  @Test("POST without CSRF cookie is rejected (403)")
  func rejectsMissingCookie() async throws {
    let app = try await SponsorTestEnv.makeApp()
    defer { Task { try? await app.asyncShutdown() } }
    _ = try await SponsorTestEnv.conference(app)
    // HostRoutingMiddleware sets isSponsorHost flag which SponsorHostOnlyMiddleware reads.
    app.middleware.use(HostRoutingMiddleware(sponsorHost: Self.sponsorHost))
    setenv("SPONSOR_HOST", Self.sponsorHost, 1)
    try app.register(collection: SponsorRoutes())

    try await app.testing().test(
      .POST, "inquiry",
      beforeRequest: { req in
        req.headers.replaceOrAdd(name: .host, value: Self.sponsorHost)
        try req.content.encode(
          [
            "companyName": "Acme",
            "contactName": "Alice",
            "email": "alice@example.com",
            "message": "x",
          ], as: .urlEncodedForm)
      }
    ) { res in
      #expect(res.status == .forbidden)
    }
  }

  @Test("POST with cookie but missing _csrf field is rejected (403)")
  func rejectsMissingFormField() async throws {
    let app = try await SponsorTestEnv.makeApp()
    defer { Task { try? await app.asyncShutdown() } }
    _ = try await SponsorTestEnv.conference(app)
    app.middleware.use(HostRoutingMiddleware(sponsorHost: Self.sponsorHost))
    setenv("SPONSOR_HOST", Self.sponsorHost, 1)
    try app.register(collection: SponsorRoutes())

    try await app.testing().test(
      .POST, "inquiry",
      beforeRequest: { req in
        req.headers.replaceOrAdd(name: .host, value: Self.sponsorHost)
        req.headers.replaceOrAdd(
          name: .cookie,
          value: "csrf_token=0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcd"
        )
        try req.content.encode(
          [
            "companyName": "Acme",
            "contactName": "Alice",
            "email": "alice@example.com",
            "message": "x",
          ], as: .urlEncodedForm)
      }
    ) { res in
      #expect(res.status == .forbidden)
    }
  }

  @Test("POST with matching cookie and _csrf field succeeds")
  func acceptsMatchingToken() async throws {
    let app = try await SponsorTestEnv.makeApp()
    defer { Task { try? await app.asyncShutdown() } }
    _ = try await SponsorTestEnv.conference(app)
    app.middleware.use(HostRoutingMiddleware(sponsorHost: Self.sponsorHost))
    setenv("SPONSOR_HOST", Self.sponsorHost, 1)
    try app.register(collection: SponsorRoutes())

    let token = "fedcba9876543210fedcba9876543210fedcba9876543210fedcba9876543210"

    try await app.testing().test(
      .POST, "inquiry",
      beforeRequest: { req in
        req.headers.replaceOrAdd(name: .host, value: Self.sponsorHost)
        req.headers.replaceOrAdd(name: .cookie, value: "csrf_token=\(token)")
        try req.content.encode(
          [
            "companyName": "Acme",
            "contactName": "Alice",
            "email": "alice@example.com",
            "message": "x",
            "_csrf": token,
          ], as: .urlEncodedForm)
      }
    ) { res in
      #expect(
        res.status == .seeOther, "Expected 303 redirect to /inquiry/thanks, got \(res.status)")
      #expect(res.headers.first(name: .location) == "/inquiry/thanks")
    }

    // Confirm the inquiry actually persisted (proves the controller ran past CSRF).
    let inquiry = try await SponsorInquiry.query(on: app.db).first()
    #expect(inquiry?.companyName == "Acme")
  }
}
