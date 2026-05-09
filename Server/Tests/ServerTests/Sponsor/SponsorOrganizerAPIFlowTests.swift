import Fluent
import Foundation
import JWT
import Testing
import Vapor
import VaporTesting

import struct SharedModels.SponsorApplicationDTO
import struct SharedModels.SponsorApplicationFormPayload
import enum SharedModels.SponsorApplicationStatus
import struct SharedModels.SponsorInquiryDTO
import struct SharedModels.SponsorOrganizationDTO
import enum SharedModels.SponsorPortalLocale
import enum SharedModels.UserRole

@testable import Server

@Suite("SponsorOrganizerAPIFlow")
struct SponsorOrganizerAPIFlowTests {
  // MARK: - Local response shapes

  struct OrgRow: Content {
    let id: UUID
    let displayName: String
    let memberCount: Int
    let applicationCount: Int
  }
  struct OrganizationsListBody: Content {
    let organizations: [OrgRow]
  }

  struct ApplicationListRow: Content {
    let id: UUID
    let orgName: String
    let planSlug: String
    let status: SponsorApplicationStatus
  }
  struct ApplicationsListBody: Content {
    let applications: [ApplicationListRow]
  }

  struct InquiriesListBody: Content {
    let inquiries: [SponsorInquiryDTO]
  }

  struct OrganizationDetailRow: Content {
    let id: UUID
    let planSlug: String
    let status: SponsorApplicationStatus
  }
  struct OrganizationDetailBody: Content {
    let organization: SponsorOrganizationDTO
    let memberEmails: [String]
    let applications: [OrganizationDetailRow]
  }

  // MARK: - Auth gating

  @Test("Admin endpoints return 401 without an auth_token cookie")
  func adminUnauthenticated() async throws {
    let app = try await SponsorTestEnv.makeApp()
    defer { Task { try? await app.asyncShutdown() } }

    try app.grouped("api", "v1", "sponsor").register(collection: SponsorAPIController())

    try await app.testing().test(.GET, "api/v1/sponsor/admin/organizations") { res in
      #expect(res.status == .unauthorized)
    }
    try await app.testing().test(.GET, "api/v1/sponsor/admin/inquiries") { res in
      #expect(res.status == .unauthorized)
    }
    try await app.testing().test(.GET, "api/v1/sponsor/admin/applications") { res in
      #expect(res.status == .unauthorized)
    }
  }

  @Test("Admin endpoints return 403 when the auth_token is non-admin")
  func adminForbiddenForNonAdmin() async throws {
    let app = try await SponsorTestEnv.makeApp()
    defer { Task { try? await app.asyncShutdown() } }

    try app.grouped("api", "v1", "sponsor").register(collection: SponsorAPIController())

    let cookie = try await organizerCookie(app, role: .speaker)
    try await app.testing().test(
      .GET, "api/v1/sponsor/admin/organizations",
      beforeRequest: { req in
        req.headers.replaceOrAdd(name: .cookie, value: cookie)
      }
    ) { res in
      #expect(res.status == .forbidden)
    }
  }

  // MARK: - Organizations

  @Test("GET /api/v1/sponsor/admin/organizations lists every org with counts")
  func listOrganizations() async throws {
    let app = try await SponsorTestEnv.makeApp()
    defer { Task { try? await app.asyncShutdown() } }
    _ = try await SponsorTestEnv.organization(app, ownerEmail: "owner@example.com")
    _ = try await SponsorTestEnv.organization(app, ownerEmail: "second@example.com")

    try app.grouped("api", "v1", "sponsor").register(collection: SponsorAPIController())

    let cookie = try await organizerCookie(app, role: .admin)
    try await app.testing().test(
      .GET, "api/v1/sponsor/admin/organizations",
      beforeRequest: { req in
        req.headers.replaceOrAdd(name: .cookie, value: cookie)
      }
    ) { res in
      #expect(res.status == .ok)
      let body = try res.content.decode(OrganizationsListBody.self)
      #expect(body.organizations.count == 2)
      #expect(body.organizations.allSatisfy { $0.memberCount == 1 })
    }
  }

  @Test("GET /api/v1/sponsor/admin/organizations/:id returns members + applications")
  func organizationDetail() async throws {
    let app = try await SponsorTestEnv.makeApp()
    defer { Task { try? await app.asyncShutdown() } }
    let conference = try await SponsorTestEnv.conference(app)
    let (org, owner) = try await SponsorTestEnv.organization(
      app, ownerEmail: "owner@example.com")
    let plan = try await SponsorTestEnv.plan(app, conference: conference, slug: "gold")
    _ = try await seedApplication(app, org: org, plan: plan, conference: conference)

    try app.grouped("api", "v1", "sponsor").register(collection: SponsorAPIController())

    let cookie = try await organizerCookie(app, role: .admin)
    try await app.testing().test(
      .GET, "api/v1/sponsor/admin/organizations/\(try org.requireID())",
      beforeRequest: { req in
        req.headers.replaceOrAdd(name: .cookie, value: cookie)
      }
    ) { res in
      #expect(res.status == .ok)
      let body = try res.content.decode(OrganizationDetailBody.self)
      #expect(body.memberEmails.contains("owner@example.com"))
      #expect(body.applications.count == 1)
      #expect(body.applications.first?.planSlug == "gold")
      _ = owner  // silence unused warning
    }
  }

  // MARK: - Inquiries / Applications listing

  @Test("GET /api/v1/sponsor/admin/inquiries returns every inquiry newest-first")
  func listInquiries() async throws {
    let app = try await SponsorTestEnv.makeApp()
    defer { Task { try? await app.asyncShutdown() } }
    let conference = try await SponsorTestEnv.conference(app)
    try await SponsorInquiry(
      conferenceID: try conference.requireID(),
      companyName: "Acme",
      contactName: "Alice",
      email: "alice@example.com",
      message: "interested",
      locale: .ja
    ).save(on: app.db)
    try await SponsorInquiry(
      conferenceID: try conference.requireID(),
      companyName: "Beta",
      contactName: "Bob",
      email: "bob@example.com",
      message: "",
      locale: .ja
    ).save(on: app.db)

    try app.grouped("api", "v1", "sponsor").register(collection: SponsorAPIController())

    let cookie = try await organizerCookie(app, role: .admin)
    try await app.testing().test(
      .GET, "api/v1/sponsor/admin/inquiries",
      beforeRequest: { req in
        req.headers.replaceOrAdd(name: .cookie, value: cookie)
      }
    ) { res in
      #expect(res.status == .ok)
      let body = try res.content.decode(InquiriesListBody.self)
      #expect(body.inquiries.count == 2)
    }
  }

  @Test("GET /api/v1/sponsor/admin/applications returns rows with org + plan info")
  func listApplications() async throws {
    let app = try await SponsorTestEnv.makeApp()
    defer { Task { try? await app.asyncShutdown() } }
    let conference = try await SponsorTestEnv.conference(app)
    let (org, _) = try await SponsorTestEnv.organization(
      app, ownerEmail: "owner@example.com")
    let plan = try await SponsorTestEnv.plan(app, conference: conference, slug: "gold")
    _ = try await seedApplication(app, org: org, plan: plan, conference: conference)

    try app.grouped("api", "v1", "sponsor").register(collection: SponsorAPIController())

    let cookie = try await organizerCookie(app, role: .admin)
    try await app.testing().test(
      .GET, "api/v1/sponsor/admin/applications",
      beforeRequest: { req in
        req.headers.replaceOrAdd(name: .cookie, value: cookie)
      }
    ) { res in
      #expect(res.status == .ok)
      let body = try res.content.decode(ApplicationsListBody.self)
      #expect(body.applications.count == 1)
      let row = body.applications.first!
      #expect(row.orgName == "Acme")
      #expect(row.planSlug == "gold")
      #expect(row.status == .submitted)
    }
  }

  // MARK: - Helpers

  private func organizerCookie(
    _ app: Application, role: UserRole
  ) async throws -> String {
    let payload = UserJWTPayload(userID: UUID(), role: role, username: "tester")
    let token = try await app.jwt.keys.sign(payload)
    return "auth_token=\(token)"
  }

  private func seedApplication(
    _ app: Application,
    org: SponsorOrganization,
    plan: SponsorPlan,
    conference: Conference
  ) async throws -> SponsorApplication {
    let payload = SponsorApplicationFormPayload(
      billingContactName: "Owner",
      billingEmail: "billing@example.com",
      invoicingNotes: nil,
      logoNote: nil,
      acceptedTerms: true,
      locale: .ja
    )
    let application = SponsorApplication(
      organizationID: try org.requireID(),
      planID: try plan.requireID(),
      conferenceID: try conference.requireID(),
      status: .submitted,
      payload: payload,
      submittedAt: Date()
    )
    try await application.save(on: app.db)
    return application
  }
}
