import Fluent
import Foundation
import JWT
import SharedModels
import Testing
import Vapor
import VaporTesting

@testable import Server

@Suite("SponsorPublicAPIFlow")
struct SponsorPublicAPIFlowTests {
  @Test("GET /api/v1/sponsor/me returns 401 without cookie, 200 with valid JWT")
  func meEndpoint() async throws {
    let app = try await SponsorTestEnv.makeApp()
    defer { Task { try? await app.asyncShutdown() } }
    _ = try await SponsorTestEnv.conference(app)
    let user = try await SponsorTestEnv.sponsorUser(app, email: "alice@example.com")

    try app.grouped("api", "v1", "sponsor").register(collection: SponsorAPIController())

    // No cookie → 401.
    try await app.testing().test(.GET, "api/v1/sponsor/me") { res in
      #expect(res.status == .unauthorized)
    }

    // With a valid sponsor JWT cookie → 200.
    let payload = SponsorJWTPayload(
      userID: try user.requireID(), orgID: nil, role: nil, locale: .ja)
    let token = try await app.jwt.keys.sign(payload)
    let cookieHeader = "\(SponsorAuthCookie.name)=\(token)"

    try await app.testing().test(
      .GET, "api/v1/sponsor/me",
      beforeRequest: { req in
        req.headers.replaceOrAdd(name: .cookie, value: cookieHeader)
      }
    ) { res in
      #expect(res.status == .ok)
      let body = res.body.string
      #expect(body.contains("\"email\":\"alice@example.com\""))
    }
  }

  @Test("GET /api/v1/sponsor/me includes organization when JWT carries orgID")
  func meEndpointWithOrganization() async throws {
    let app = try await SponsorTestEnv.makeApp()
    defer { Task { try? await app.asyncShutdown() } }
    _ = try await SponsorTestEnv.conference(app)
    let (org, owner) = try await SponsorTestEnv.organization(
      app, ownerEmail: "owner@example.com")

    try app.grouped("api", "v1", "sponsor").register(collection: SponsorAPIController())

    let payload = SponsorJWTPayload(
      userID: try owner.requireID(),
      orgID: try org.requireID(),
      role: .owner,
      locale: .ja)
    let token = try await app.jwt.keys.sign(payload)
    let cookieHeader = "\(SponsorAuthCookie.name)=\(token)"

    try await app.testing().test(
      .GET, "api/v1/sponsor/me",
      beforeRequest: { req in
        req.headers.replaceOrAdd(name: .cookie, value: cookieHeader)
      }
    ) { res in
      #expect(res.status == .ok)
      let body = res.body.string
      #expect(body.contains("\"role\":\"owner\""))
      #expect(body.contains("\"legalName\":\"Acme Inc.\""))
    }
  }

  @Test("GET /api/v1/sponsor/plans lists active plans for the accepting conference")
  func plansEndpoint() async throws {
    let app = try await SponsorTestEnv.makeApp()
    defer { Task { try? await app.asyncShutdown() } }
    let conference = try await SponsorTestEnv.conference(app)
    _ = try await SponsorTestEnv.plan(app, conference: conference, slug: "gold")
    _ = try await SponsorTestEnv.plan(app, conference: conference, slug: "silver")

    try app.grouped("api", "v1", "sponsor").register(collection: SponsorAPIController())

    try await app.testing().test(.GET, "api/v1/sponsor/plans") { res in
      #expect(res.status == .ok)
      let body = res.body.string
      #expect(body.contains("\"slug\":\"gold\""))
      #expect(body.contains("\"slug\":\"silver\""))
    }
  }

  @Test("GET /api/v1/sponsor/plans returns 503 when no conference is accepting sponsors")
  func plansWhenNoAcceptingConference() async throws {
    let app = try await SponsorTestEnv.makeApp()
    defer { Task { try? await app.asyncShutdown() } }
    _ = try await SponsorTestEnv.conference(app, isAcceptingSponsors: false)

    try app.grouped("api", "v1", "sponsor").register(collection: SponsorAPIController())

    try await app.testing().test(.GET, "api/v1/sponsor/plans") { res in
      #expect(res.status == .serviceUnavailable)
    }
  }

  @Test("POST /api/v1/sponsor/logout returns 200 and emits an expired Set-Cookie")
  func logoutEndpoint() async throws {
    let app = try await SponsorTestEnv.makeApp()
    defer { Task { try? await app.asyncShutdown() } }

    try app.grouped("api", "v1", "sponsor").register(collection: SponsorAPIController())

    try await app.testing().test(.POST, "api/v1/sponsor/logout") { res in
      #expect(res.status == .ok)
      let setCookie = res.headers.first(name: .setCookie) ?? ""
      #expect(setCookie.contains(SponsorAuthCookie.name))
      // Either Max-Age=0 or an Expires in the past must be emitted so the
      // browser drops the cookie immediately.
      #expect(setCookie.contains("Max-Age=0") || setCookie.contains("Expires=Thu, 01 Jan 1970"))
    }
  }
}
