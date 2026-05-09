import Fluent
import Foundation
import JWT
import Testing
import Vapor
import VaporTesting

import struct SharedModels.SponsorApplicationDTO
import struct SharedModels.SponsorApplicationFormPayload
import enum SharedModels.SponsorApplicationStatus
import enum SharedModels.SponsorMemberRole
import enum SharedModels.SponsorPortalLocale

@testable import Server

@Suite("SponsorApplicationAPIFlow")
struct SponsorApplicationAPIFlowTests {
  // Local Codable mirror of the controller-private response shape.
  struct DetailResponseBody: Content {
    let application: SponsorApplicationDTO
    let planName: String
    let canWithdraw: Bool
  }

  // MARK: - GET /me/application

  @Test("GET /api/v1/sponsor/me/application returns 401 without cookie")
  func myApplicationUnauthenticated() async throws {
    let app = try await SponsorTestEnv.makeApp()
    defer { Task { try? await app.asyncShutdown() } }
    _ = try await SponsorTestEnv.conference(app)

    try app.grouped("api", "v1", "sponsor").register(collection: SponsorAPIController())

    try await app.testing().test(.GET, "api/v1/sponsor/me/application") { res in
      #expect(res.status == .unauthorized)
    }
  }

  @Test("GET /api/v1/sponsor/me/application returns 404 when user has no organization")
  func myApplicationNoOrg() async throws {
    let app = try await SponsorTestEnv.makeApp()
    defer { Task { try? await app.asyncShutdown() } }
    _ = try await SponsorTestEnv.conference(app)
    let user = try await SponsorTestEnv.sponsorUser(app, email: "lonely@example.com")

    try app.grouped("api", "v1", "sponsor").register(collection: SponsorAPIController())

    let cookie = try await signSponsorCookie(app, userID: try user.requireID())
    try await app.testing().test(
      .GET, "api/v1/sponsor/me/application",
      beforeRequest: { req in
        req.headers.replaceOrAdd(name: .cookie, value: cookie)
      }
    ) { res in
      #expect(res.status == .notFound)
    }
  }

  @Test("GET /api/v1/sponsor/me/application returns the latest application for the user's org")
  func myApplicationHappyPath() async throws {
    let app = try await SponsorTestEnv.makeApp()
    defer { Task { try? await app.asyncShutdown() } }
    let conference = try await SponsorTestEnv.conference(app)
    let (org, owner) = try await SponsorTestEnv.organization(
      app, ownerEmail: "owner@example.com")
    let plan = try await SponsorTestEnv.plan(app, conference: conference, slug: "gold")
    let saved = try await seedApplication(
      app, organization: org, plan: plan, conference: conference)

    try app.grouped("api", "v1", "sponsor").register(collection: SponsorAPIController())

    let cookie = try await signSponsorCookie(
      app, userID: try owner.requireID(), orgID: try org.requireID(), role: .owner)
    try await app.testing().test(
      .GET, "api/v1/sponsor/me/application",
      beforeRequest: { req in
        req.headers.replaceOrAdd(name: .cookie, value: cookie)
      }
    ) { res in
      #expect(res.status == .ok)
      let body = try res.content.decode(SponsorApplicationDTO.self)
      #expect(body.id == (try saved.requireID()))
      #expect(body.status == .submitted)
    }
  }

  // MARK: - POST /applications

  @Test("POST /api/v1/sponsor/applications creates a SponsorApplication and returns 201")
  func createApplicationHappyPath() async throws {
    let app = try await SponsorTestEnv.makeApp()
    defer { Task { try? await app.asyncShutdown() } }
    let conference = try await SponsorTestEnv.conference(app)
    let (org, owner) = try await SponsorTestEnv.organization(
      app, ownerEmail: "owner@example.com")
    _ = try await SponsorTestEnv.plan(app, conference: conference, slug: "gold")

    try app.grouped("api", "v1", "sponsor").register(collection: SponsorAPIController())

    struct CreatePayload: Content {
      let planSlug: String
      let billingContactName: String
      let billingEmail: String
      let invoicingNotes: String?
      let logoNote: String?
      let acceptedTerms: Bool
    }

    let cookie = try await signSponsorCookie(
      app, userID: try owner.requireID(), orgID: try org.requireID(), role: .owner)

    try await app.testing().test(
      .POST, "api/v1/sponsor/applications",
      beforeRequest: { req in
        req.headers.replaceOrAdd(name: .cookie, value: cookie)
        try req.content.encode(
          CreatePayload(
            planSlug: "gold",
            billingContactName: "Owner",
            billingEmail: "billing@example.com",
            invoicingNotes: nil,
            logoNote: nil,
            acceptedTerms: true
          )
        )
      }
    ) { res in
      #expect(res.status == .created)
      let body = try res.content.decode(SponsorApplicationDTO.self)
      #expect(body.status == .submitted)
    }

    let saved = try await SponsorApplication.query(on: app.db).all()
    #expect(saved.count == 1)
  }

  @Test("POST /api/v1/sponsor/applications rejects when acceptedTerms is false")
  func createApplicationTermsRequired() async throws {
    let app = try await SponsorTestEnv.makeApp()
    defer { Task { try? await app.asyncShutdown() } }
    let conference = try await SponsorTestEnv.conference(app)
    let (org, owner) = try await SponsorTestEnv.organization(
      app, ownerEmail: "owner@example.com")
    _ = try await SponsorTestEnv.plan(app, conference: conference, slug: "gold")

    try app.grouped("api", "v1", "sponsor").register(collection: SponsorAPIController())

    struct CreatePayload: Content {
      let planSlug: String
      let billingContactName: String
      let billingEmail: String
      let invoicingNotes: String?
      let logoNote: String?
      let acceptedTerms: Bool
    }

    let cookie = try await signSponsorCookie(
      app, userID: try owner.requireID(), orgID: try org.requireID(), role: .owner)

    try await app.testing().test(
      .POST, "api/v1/sponsor/applications",
      beforeRequest: { req in
        req.headers.replaceOrAdd(name: .cookie, value: cookie)
        try req.content.encode(
          CreatePayload(
            planSlug: "gold",
            billingContactName: "Owner",
            billingEmail: "billing@example.com",
            invoicingNotes: nil,
            logoNote: nil,
            acceptedTerms: false
          )
        )
      }
    ) { res in
      #expect(res.status == .badRequest)
    }
  }

  // MARK: - GET /applications/:id

  @Test("GET /api/v1/sponsor/applications/:id returns detail with canWithdraw=true for owner")
  func detailOwnerCanWithdraw() async throws {
    let app = try await SponsorTestEnv.makeApp()
    defer { Task { try? await app.asyncShutdown() } }
    let conference = try await SponsorTestEnv.conference(app)
    let (org, owner) = try await SponsorTestEnv.organization(
      app, ownerEmail: "owner@example.com")
    let plan = try await SponsorTestEnv.plan(app, conference: conference, slug: "gold")
    let saved = try await seedApplication(
      app, organization: org, plan: plan, conference: conference)

    try app.grouped("api", "v1", "sponsor").register(collection: SponsorAPIController())

    let cookie = try await signSponsorCookie(
      app, userID: try owner.requireID(), orgID: try org.requireID(), role: .owner)

    try await app.testing().test(
      .GET, "api/v1/sponsor/applications/\(try saved.requireID())",
      beforeRequest: { req in
        req.headers.replaceOrAdd(name: .cookie, value: cookie)
      }
    ) { res in
      #expect(res.status == .ok)
      let body = try res.content.decode(DetailResponseBody.self)
      #expect(body.application.status == .submitted)
      #expect(body.canWithdraw == true)
      #expect(body.planName == "Gold")
    }
  }

  @Test("GET /api/v1/sponsor/applications/:id returns 403 for non-member")
  func detailForbiddenForNonMember() async throws {
    let app = try await SponsorTestEnv.makeApp()
    defer { Task { try? await app.asyncShutdown() } }
    let conference = try await SponsorTestEnv.conference(app)
    let (org, _) = try await SponsorTestEnv.organization(
      app, ownerEmail: "owner@example.com")
    let plan = try await SponsorTestEnv.plan(app, conference: conference, slug: "gold")
    let saved = try await seedApplication(
      app, organization: org, plan: plan, conference: conference)
    let outsider = try await SponsorTestEnv.sponsorUser(app, email: "outsider@example.com")

    try app.grouped("api", "v1", "sponsor").register(collection: SponsorAPIController())

    let cookie = try await signSponsorCookie(app, userID: try outsider.requireID())
    try await app.testing().test(
      .GET, "api/v1/sponsor/applications/\(try saved.requireID())",
      beforeRequest: { req in
        req.headers.replaceOrAdd(name: .cookie, value: cookie)
      }
    ) { res in
      #expect(res.status == .forbidden)
    }
  }

  // MARK: - POST /applications/:id/withdraw

  @Test("POST /api/v1/sponsor/applications/:id/withdraw flips status to withdrawn for owner")
  func withdrawHappyPath() async throws {
    let app = try await SponsorTestEnv.makeApp()
    defer { Task { try? await app.asyncShutdown() } }
    let conference = try await SponsorTestEnv.conference(app)
    let (org, owner) = try await SponsorTestEnv.organization(
      app, ownerEmail: "owner@example.com")
    let plan = try await SponsorTestEnv.plan(app, conference: conference, slug: "gold")
    let saved = try await seedApplication(
      app, organization: org, plan: plan, conference: conference)

    try app.grouped("api", "v1", "sponsor").register(collection: SponsorAPIController())

    let cookie = try await signSponsorCookie(
      app, userID: try owner.requireID(), orgID: try org.requireID(), role: .owner)

    try await app.testing().test(
      .POST, "api/v1/sponsor/applications/\(try saved.requireID())/withdraw",
      beforeRequest: { req in
        req.headers.replaceOrAdd(name: .cookie, value: cookie)
      }
    ) { res in
      #expect(res.status == .ok)
      let body = try res.content.decode(SponsorApplicationDTO.self)
      #expect(body.status == .withdrawn)
    }

    let reloaded = try await SponsorApplication.find(try saved.requireID(), on: app.db)
    #expect(reloaded?.status == .withdrawn)
  }

  @Test("POST /api/v1/sponsor/applications/:id/withdraw returns 409 once review has begun")
  func withdrawConflictAfterReview() async throws {
    let app = try await SponsorTestEnv.makeApp()
    defer { Task { try? await app.asyncShutdown() } }
    let conference = try await SponsorTestEnv.conference(app)
    let (org, owner) = try await SponsorTestEnv.organization(
      app, ownerEmail: "owner@example.com")
    let plan = try await SponsorTestEnv.plan(app, conference: conference, slug: "gold")
    let saved = try await seedApplication(
      app, organization: org, plan: plan, conference: conference)
    saved.status = .approved
    try await saved.save(on: app.db)

    try app.grouped("api", "v1", "sponsor").register(collection: SponsorAPIController())

    let cookie = try await signSponsorCookie(
      app, userID: try owner.requireID(), orgID: try org.requireID(), role: .owner)

    try await app.testing().test(
      .POST, "api/v1/sponsor/applications/\(try saved.requireID())/withdraw",
      beforeRequest: { req in
        req.headers.replaceOrAdd(name: .cookie, value: cookie)
      }
    ) { res in
      #expect(res.status == .conflict)
    }
  }

  // MARK: - Helpers

  private func signSponsorCookie(
    _ app: Application,
    userID: UUID,
    orgID: UUID? = nil,
    role: SponsorMemberRole? = nil,
    locale: SponsorPortalLocale = .ja
  ) async throws -> String {
    let payload = SponsorJWTPayload(
      userID: userID, orgID: orgID, role: role, locale: locale)
    let token = try await app.jwt.keys.sign(payload)
    return "\(SponsorAuthCookie.name)=\(token)"
  }

  private func seedApplication(
    _ app: Application,
    organization: SponsorOrganization,
    plan: SponsorPlan,
    conference: Conference
  ) async throws -> SponsorApplication {
    let formPayload = SponsorApplicationFormPayload(
      billingContactName: "Owner",
      billingEmail: "billing@example.com",
      invoicingNotes: nil,
      logoNote: nil,
      acceptedTerms: true,
      locale: .ja
    )
    let application = SponsorApplication(
      organizationID: try organization.requireID(),
      planID: try plan.requireID(),
      conferenceID: try conference.requireID(),
      status: .submitted,
      payload: formPayload,
      submittedAt: Date()
    )
    try await application.save(on: app.db)
    return application
  }
}
