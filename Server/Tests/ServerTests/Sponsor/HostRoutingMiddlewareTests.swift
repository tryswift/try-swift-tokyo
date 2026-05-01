import Foundation
import Testing
import Vapor
import VaporTesting

@testable import Server

@Suite("HostRoutingMiddleware")
struct HostRoutingMiddlewareTests {
  @Test("sets isSponsorHost storage flag for sponsor.tryswift.jp")
  func setsFlag() async throws {
    let app = try await Application.make(.testing)
    defer { Task { try? await app.asyncShutdown() } }
    app.middleware.use(HostRoutingMiddleware(sponsorHost: "sponsor.tryswift.jp"))
    app.get("debug-host") { req in
      req.isSponsorHost ? "sponsor" : "other"
    }
    try await app.testing().test(
      .GET, "debug-host",
      beforeRequest: { req in req.headers.add(name: .host, value: "sponsor.tryswift.jp") }
    ) { res in
      #expect(res.status == .ok)
      #expect(res.body.string == "sponsor")
    }
    try await app.testing().test(
      .GET, "debug-host",
      beforeRequest: { req in req.headers.replaceOrAdd(name: .host, value: "api.tryswift.jp") }
    ) { res in
      #expect(res.body.string == "other")
    }
  }
}
