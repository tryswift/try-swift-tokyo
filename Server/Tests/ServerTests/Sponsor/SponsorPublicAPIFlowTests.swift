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
  // Local Codable mirrors of the controller-private response shapes so tests
  // assert on decoded values (Copilot review feedback on #479) instead of
  // raw JSON substrings.

  struct MeResponseBody: Content {
    let id: UUID
    let email: String
    let displayName: String?
    let role: SponsorMemberRole?
    let organization: SponsorOrganizationDTO?
  }

  struct PlansResponseBody: Content {
    let plans: [SponsorPlanDTO]
  }

  struct OkResponseBody: Content {
    let ok: Bool
  }

  struct VerifyResponseBody: Content {
    let id: UUID
    let email: String
    let role: SponsorMemberRole?
    let organization: SponsorOrganizationDTO?
  }

  // MARK: - GET /me

  @Test("GET /api/v1/sponsor/me returns 401 without cookie, 200 with valid JWT")
  func meEndpoint() async throws {
    let app = try await SponsorTestEnv.makeApp()
    defer { Task { try? await app.asyncShutdown() } }
    _ = try await SponsorTestEnv.conference(app)
    let user = try await SponsorTestEnv.sponsorUser(app, email: "alice@example.com")

    try app.grouped("api", "v1", "sponsor").register(collection: SponsorAPIController())

    try await app.testing().test(.GET, "api/v1/sponsor/me") { res in
      #expect(res.status == .unauthorized)
    }

    let token = try await app.jwt.keys.sign(
      SponsorJWTPayload(userID: try user.requireID(), orgID: nil, role: nil, locale: .ja))
    let cookieHeader = "\(SponsorAuthCookie.name)=\(token)"

    try await app.testing().test(
      .GET, "api/v1/sponsor/me",
      beforeRequest: { req in
        req.headers.replaceOrAdd(name: .cookie, value: cookieHeader)
      }
    ) { res in
      #expect(res.status == .ok)
      let body = try res.content.decode(MeResponseBody.self)
      #expect(body.email == "alice@example.com")
      #expect(body.role == nil)
      #expect(body.organization == nil)
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

    let token = try await app.jwt.keys.sign(
      SponsorJWTPayload(
        userID: try owner.requireID(),
        orgID: try org.requireID(),
        role: .owner,
        locale: .ja))
    let cookieHeader = "\(SponsorAuthCookie.name)=\(token)"

    try await app.testing().test(
      .GET, "api/v1/sponsor/me",
      beforeRequest: { req in
        req.headers.replaceOrAdd(name: .cookie, value: cookieHeader)
      }
    ) { res in
      #expect(res.status == .ok)
      let body = try res.content.decode(MeResponseBody.self)
      #expect(body.email == "owner@example.com")
      #expect(body.role == .owner)
      #expect(body.organization?.legalName == "Acme Inc.")
    }
  }

  // MARK: - GET /plans

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
      let body = try res.content.decode(PlansResponseBody.self)
      let slugs = Set(body.plans.map(\.slug))
      #expect(slugs == ["gold", "silver"])
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

  // MARK: - POST /logout

  @Test("POST /api/v1/sponsor/logout returns 200 and emits an expired cookie")
  func logoutEndpoint() async throws {
    let app = try await SponsorTestEnv.makeApp()
    defer { Task { try? await app.asyncShutdown() } }

    try app.grouped("api", "v1", "sponsor").register(collection: SponsorAPIController())

    try await app.testing().test(.POST, "api/v1/sponsor/logout") { res in
      #expect(res.status == .ok)
      let body = try res.content.decode(OkResponseBody.self)
      #expect(body.ok == true)

      let setCookie = res.headers.first(name: .setCookie) ?? ""
      let parsed = parseSetCookie(setCookie)
      #expect(parsed.name == SponsorAuthCookie.name)
      #expect(parsed.value.isEmpty)
      // Either Max-Age=0 *or* an Expires in the past — both are valid ways
      // to invalidate the cookie. We don't assert the date format here.
      #expect(parsed.maxAge == 0 || (parsed.expires.map { $0 <= Date() } ?? false))
    }
  }

  // MARK: - POST /inquiries

  @Test("POST /api/v1/sponsor/inquiries creates SponsorInquiry + SponsorUser + MagicLink")
  func createInquiry() async throws {
    let app = try await SponsorTestEnv.makeApp()
    defer { Task { try? await app.asyncShutdown() } }
    _ = try await SponsorTestEnv.conference(app)

    try app.grouped("api", "v1", "sponsor").register(collection: SponsorAPIController())

    try await app.testing().test(
      .POST, "api/v1/sponsor/inquiries",
      beforeRequest: { req in
        try req.content.encode(
          SponsorInquiryFormPayload(
            companyName: "Acme",
            contactName: "Alice",
            email: "alice@example.com",
            message: "interested in Gold"
          ))
      }
    ) { res in
      #expect(res.status == .ok)
      let body = try res.content.decode(OkResponseBody.self)
      #expect(body.ok == true)
    }

    let inquiry = try await SponsorInquiry.query(on: app.db).first()
    #expect(inquiry?.companyName == "Acme")
    let user = try await SponsorUser.query(on: app.db).first()
    #expect(user?.email == "alice@example.com")
    let tokens = try await MagicLinkToken.query(on: app.db).all()
    #expect(tokens.count == 1)
  }

  @Test("POST /api/v1/sponsor/inquiries returns 503 when no accepting conference")
  func createInquiryNoAcceptingConference() async throws {
    let app = try await SponsorTestEnv.makeApp()
    defer { Task { try? await app.asyncShutdown() } }
    _ = try await SponsorTestEnv.conference(app, isAcceptingSponsors: false)

    try app.grouped("api", "v1", "sponsor").register(collection: SponsorAPIController())

    try await app.testing().test(
      .POST, "api/v1/sponsor/inquiries",
      beforeRequest: { req in
        try req.content.encode(
          SponsorInquiryFormPayload(
            companyName: "Acme",
            contactName: "Alice",
            email: "alice@example.com",
            message: nil
          ))
      }
    ) { res in
      #expect(res.status == .serviceUnavailable)
    }
  }

  // MARK: - POST /login

  @Test("POST /api/v1/sponsor/login issues a magic-link token for an existing user")
  func requestMagicLinkExistingUser() async throws {
    let app = try await SponsorTestEnv.makeApp()
    defer { Task { try? await app.asyncShutdown() } }
    _ = try await SponsorTestEnv.conference(app)
    _ = try await SponsorTestEnv.sponsorUser(app, email: "bob@example.com")

    try app.grouped("api", "v1", "sponsor").register(collection: SponsorAPIController())

    try await app.testing().test(
      .POST, "api/v1/sponsor/login",
      beforeRequest: { req in
        try req.content.encode(MagicLinkRequestPayload(email: "bob@example.com"))
      }
    ) { res in
      #expect(res.status == .ok)
      let body = try res.content.decode(OkResponseBody.self)
      #expect(body.ok == true)
    }

    let tokens = try await MagicLinkToken.query(on: app.db).all()
    #expect(tokens.count == 1)
  }

  @Test("POST /api/v1/sponsor/login returns 200 even when user does not exist (no enumeration)")
  func requestMagicLinkUnknownUser() async throws {
    let app = try await SponsorTestEnv.makeApp()
    defer { Task { try? await app.asyncShutdown() } }
    _ = try await SponsorTestEnv.conference(app)

    try app.grouped("api", "v1", "sponsor").register(collection: SponsorAPIController())

    try await app.testing().test(
      .POST, "api/v1/sponsor/login",
      beforeRequest: { req in
        try req.content.encode(MagicLinkRequestPayload(email: "nobody@example.com"))
      }
    ) { res in
      #expect(res.status == .ok)
    }

    let tokens = try await MagicLinkToken.query(on: app.db).all()
    #expect(tokens.isEmpty)
    let users = try await SponsorUser.query(on: app.db).all()
    #expect(users.isEmpty)
  }

  // MARK: - GET /auth/verify

  @Test("GET /api/v1/sponsor/auth/verify sets sponsor cookie and returns user info")
  func verifyMagicLinkSetsCookie() async throws {
    let app = try await SponsorTestEnv.makeApp()
    defer { Task { try? await app.asyncShutdown() } }
    _ = try await SponsorTestEnv.conference(app)
    let user = try await SponsorTestEnv.sponsorUser(app, email: "carol@example.com")
    let issued = try await MagicLinkService.issue(for: user, on: app.db)

    try app.grouped("api", "v1", "sponsor").register(collection: SponsorAPIController())

    try await app.testing().test(
      .GET, "api/v1/sponsor/auth/verify?token=\(issued.rawToken)"
    ) { res in
      #expect(res.status == .ok)
      let body = try res.content.decode(VerifyResponseBody.self)
      #expect(body.email == "carol@example.com")
      #expect(body.role == nil)
      #expect(body.organization == nil)

      let setCookie = res.headers.first(name: .setCookie) ?? ""
      let parsed = parseSetCookie(setCookie)
      #expect(parsed.name == SponsorAuthCookie.name)
      #expect(parsed.value.isEmpty == false)
    }
  }

  @Test("GET /api/v1/sponsor/auth/verify rejects invalid token with 401")
  func verifyMagicLinkInvalidToken() async throws {
    let app = try await SponsorTestEnv.makeApp()
    defer { Task { try? await app.asyncShutdown() } }
    _ = try await SponsorTestEnv.conference(app)

    try app.grouped("api", "v1", "sponsor").register(collection: SponsorAPIController())

    try await app.testing().test(
      .GET, "api/v1/sponsor/auth/verify?token=not-a-real-token"
    ) { res in
      #expect(res.status == .unauthorized)
      #expect(res.headers.first(name: .setCookie) == nil)
    }
  }
}

// MARK: - Set-Cookie parsing helper

/// Lightweight parser for the Set-Cookie response header so the tests can
/// assert on cookie value / max-age / expires without depending on the exact
/// date format used by the framework.
private struct ParsedCookie {
  let name: String
  let value: String
  let maxAge: Int?
  let expires: Date?
}

private func parseSetCookie(_ header: String) -> ParsedCookie {
  var name = ""
  var value = ""
  var maxAge: Int?
  var expires: Date?

  let attributes = header.components(separatedBy: ";").map {
    $0.trimmingCharacters(in: .whitespaces)
  }
  for (index, attribute) in attributes.enumerated() {
    if index == 0 {
      let pair = attribute.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
      if pair.count >= 1 { name = String(pair[0]) }
      if pair.count >= 2 { value = String(pair[1]) }
    } else {
      let pair = attribute.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
      let key = pair.first.map { $0.lowercased() } ?? ""
      let raw = pair.count >= 2 ? String(pair[1]) : ""
      switch key {
      case "max-age":
        maxAge = Int(raw)
      case "expires":
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
        expires = formatter.date(from: raw)
      default:
        break
      }
    }
  }
  return ParsedCookie(name: name, value: value, maxAge: maxAge, expires: expires)
}
