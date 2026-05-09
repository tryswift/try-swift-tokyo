import Fluent
import Foundation
import JWT
import Testing
import Vapor
import VaporTesting

import enum SharedModels.SponsorMemberRole
import struct SharedModels.SponsorOrganizationDTO
import enum SharedModels.SponsorPortalLocale

@testable import Server

@Suite("SponsorTeamProfileAPIFlow")
struct SponsorTeamProfileAPIFlowTests {
  // MARK: - Local response shapes

  struct ProfileResponseBody: Content {
    let organization: SponsorOrganizationDTO?
    let isOwner: Bool
  }

  struct MemberRow: Content {
    let userID: UUID
    let email: String
    let displayName: String?
    let role: SponsorMemberRole
  }

  struct TeamResponseBody: Content {
    let members: [MemberRow]
    let isOwner: Bool
  }

  struct OkResponseBody: Content {
    let ok: Bool
  }

  struct InvitationResponseBody: Content {
    let token: String
    let orgName: String
    let email: String
    let expiresAt: Date
  }

  // MARK: - Profile

  @Test("GET /api/v1/sponsor/profile returns 401 without cookie")
  func profileUnauthenticated() async throws {
    let app = try await SponsorTestEnv.makeApp()
    defer { Task { try? await app.asyncShutdown() } }

    try app.grouped("api", "v1", "sponsor").register(collection: SponsorAPIController())
    try await app.testing().test(.GET, "api/v1/sponsor/profile") { res in
      #expect(res.status == .unauthorized)
    }
  }

  @Test("GET /api/v1/sponsor/profile returns nil organization when user has no membership")
  func profileNoOrg() async throws {
    let app = try await SponsorTestEnv.makeApp()
    defer { Task { try? await app.asyncShutdown() } }
    let user = try await SponsorTestEnv.sponsorUser(app, email: "lonely@example.com")

    try app.grouped("api", "v1", "sponsor").register(collection: SponsorAPIController())

    let cookie = try await sponsorCookie(app, userID: try user.requireID())
    try await app.testing().test(
      .GET, "api/v1/sponsor/profile",
      beforeRequest: { req in
        req.headers.replaceOrAdd(name: .cookie, value: cookie)
      }
    ) { res in
      #expect(res.status == .ok)
      let body = try res.content.decode(ProfileResponseBody.self)
      #expect(body.organization == nil)
      #expect(body.isOwner == false)
    }
  }

  @Test("PUT /api/v1/sponsor/profile creates a new organization with owner membership")
  func profileCreatesOrgAndMembership() async throws {
    let app = try await SponsorTestEnv.makeApp()
    defer { Task { try? await app.asyncShutdown() } }
    let user = try await SponsorTestEnv.sponsorUser(app, email: "founder@example.com")

    try app.grouped("api", "v1", "sponsor").register(collection: SponsorAPIController())

    let cookie = try await sponsorCookie(app, userID: try user.requireID())
    try await app.testing().test(
      .PUT, "api/v1/sponsor/profile",
      beforeRequest: { req in
        req.headers.replaceOrAdd(name: .cookie, value: cookie)
        try req.content.encode(
          SponsorProfileUpdatePayload(
            legalName: "Acme Inc.",
            displayName: "Acme",
            country: "JP",
            billingAddress: "Tokyo",
            websiteURL: "https://acme.example"
          )
        )
      }
    ) { res in
      #expect(res.status == .ok)
      let dto = try res.content.decode(SponsorOrganizationDTO.self)
      #expect(dto.legalName == "Acme Inc.")
    }

    let memberships = try await SponsorMembership.query(on: app.db).all()
    #expect(memberships.count == 1)
    #expect(memberships.first?.role == .owner)
  }

  @Test("PUT /api/v1/sponsor/profile rejects updates from non-owners")
  func profileUpdateForbiddenForNonOwner() async throws {
    let app = try await SponsorTestEnv.makeApp()
    defer { Task { try? await app.asyncShutdown() } }
    let (org, _) = try await SponsorTestEnv.organization(
      app, ownerEmail: "owner@example.com")
    let nonOwner = try await SponsorTestEnv.sponsorUser(app, email: "non@example.com")
    let mem = SponsorMembership(
      organizationID: try org.requireID(),
      userID: try nonOwner.requireID(),
      role: .member)
    try await mem.save(on: app.db)

    try app.grouped("api", "v1", "sponsor").register(collection: SponsorAPIController())

    let cookie = try await sponsorCookie(app, userID: try nonOwner.requireID())
    try await app.testing().test(
      .PUT, "api/v1/sponsor/profile",
      beforeRequest: { req in
        req.headers.replaceOrAdd(name: .cookie, value: cookie)
        try req.content.encode(
          SponsorProfileUpdatePayload(
            legalName: "Hostile Takeover", displayName: "Acme",
            country: nil, billingAddress: nil, websiteURL: nil
          )
        )
      }
    ) { res in
      #expect(res.status == .forbidden)
    }
  }

  // MARK: - Team

  @Test("GET /api/v1/sponsor/team lists membership rows for the user's org")
  func teamListsMembers() async throws {
    let app = try await SponsorTestEnv.makeApp()
    defer { Task { try? await app.asyncShutdown() } }
    let (org, owner) = try await SponsorTestEnv.organization(
      app, ownerEmail: "owner@example.com")
    let other = try await SponsorTestEnv.sponsorUser(app, email: "other@example.com")
    let mem = SponsorMembership(
      organizationID: try org.requireID(),
      userID: try other.requireID(),
      role: .member)
    try await mem.save(on: app.db)

    try app.grouped("api", "v1", "sponsor").register(collection: SponsorAPIController())

    let cookie = try await sponsorCookie(app, userID: try owner.requireID())
    try await app.testing().test(
      .GET, "api/v1/sponsor/team",
      beforeRequest: { req in
        req.headers.replaceOrAdd(name: .cookie, value: cookie)
      }
    ) { res in
      #expect(res.status == .ok)
      let body = try res.content.decode(TeamResponseBody.self)
      #expect(body.members.count == 2)
      #expect(body.isOwner == true)
      let owners = body.members.filter { $0.role == .owner }
      #expect(owners.count == 1)
      #expect(owners.first?.email == "owner@example.com")
    }
  }

  // MARK: - Invitations

  @Test("POST /api/v1/sponsor/team/invitations creates a SponsorInvitation for owner")
  func inviteCreatesInvitation() async throws {
    let app = try await SponsorTestEnv.makeApp()
    defer { Task { try? await app.asyncShutdown() } }
    let (_, owner) = try await SponsorTestEnv.organization(
      app, ownerEmail: "owner@example.com")

    try app.grouped("api", "v1", "sponsor").register(collection: SponsorAPIController())

    let cookie = try await sponsorCookie(app, userID: try owner.requireID())
    try await app.testing().test(
      .POST, "api/v1/sponsor/team/invitations",
      beforeRequest: { req in
        req.headers.replaceOrAdd(name: .cookie, value: cookie)
        try req.content.encode(SponsorTeamInvitePayload(email: "newbie@example.com"))
      }
    ) { res in
      #expect(res.status == .created)
      let body = try res.content.decode(OkResponseBody.self)
      #expect(body.ok == true)
    }

    let invitations = try await SponsorInvitation.query(on: app.db).all()
    #expect(invitations.count == 1)
    #expect(invitations.first?.email == "newbie@example.com")
  }

  @Test("POST /api/v1/sponsor/team/invitations is forbidden for non-owners")
  func inviteForbiddenForNonOwner() async throws {
    let app = try await SponsorTestEnv.makeApp()
    defer { Task { try? await app.asyncShutdown() } }
    let (org, _) = try await SponsorTestEnv.organization(
      app, ownerEmail: "owner@example.com")
    let nonOwner = try await SponsorTestEnv.sponsorUser(app, email: "member@example.com")
    let mem = SponsorMembership(
      organizationID: try org.requireID(),
      userID: try nonOwner.requireID(),
      role: .member)
    try await mem.save(on: app.db)

    try app.grouped("api", "v1", "sponsor").register(collection: SponsorAPIController())

    let cookie = try await sponsorCookie(app, userID: try nonOwner.requireID())
    try await app.testing().test(
      .POST, "api/v1/sponsor/team/invitations",
      beforeRequest: { req in
        req.headers.replaceOrAdd(name: .cookie, value: cookie)
        try req.content.encode(SponsorTeamInvitePayload(email: "newbie@example.com"))
      }
    ) { res in
      #expect(res.status == .forbidden)
    }
  }

  @Test("DELETE /api/v1/sponsor/team/members/:userID removes the row for owner")
  func removeMemberHappyPath() async throws {
    let app = try await SponsorTestEnv.makeApp()
    defer { Task { try? await app.asyncShutdown() } }
    let (org, owner) = try await SponsorTestEnv.organization(
      app, ownerEmail: "owner@example.com")
    let other = try await SponsorTestEnv.sponsorUser(app, email: "other@example.com")
    let mem = SponsorMembership(
      organizationID: try org.requireID(),
      userID: try other.requireID(),
      role: .member)
    try await mem.save(on: app.db)

    try app.grouped("api", "v1", "sponsor").register(collection: SponsorAPIController())

    let cookie = try await sponsorCookie(app, userID: try owner.requireID())
    try await app.testing().test(
      .DELETE, "api/v1/sponsor/team/members/\(try other.requireID())",
      beforeRequest: { req in
        req.headers.replaceOrAdd(name: .cookie, value: cookie)
      }
    ) { res in
      #expect(res.status == .ok)
    }

    let remaining = try await SponsorMembership.query(on: app.db).all()
    #expect(remaining.count == 1)
    #expect(remaining.first?.$user.id == (try owner.requireID()))
  }

  @Test("DELETE /api/v1/sponsor/team/members/:userID rejects owner self-removal")
  func removeSelfRejected() async throws {
    let app = try await SponsorTestEnv.makeApp()
    defer { Task { try? await app.asyncShutdown() } }
    let (_, owner) = try await SponsorTestEnv.organization(
      app, ownerEmail: "owner@example.com")

    try app.grouped("api", "v1", "sponsor").register(collection: SponsorAPIController())

    let cookie = try await sponsorCookie(app, userID: try owner.requireID())
    try await app.testing().test(
      .DELETE, "api/v1/sponsor/team/members/\(try owner.requireID())",
      beforeRequest: { req in
        req.headers.replaceOrAdd(name: .cookie, value: cookie)
      }
    ) { res in
      #expect(res.status == .badRequest)
    }
  }

  // MARK: - Public invitation lookup / accept

  @Test("GET /api/v1/sponsor/invitations/:token returns 404 for unknown tokens")
  func showInvitationUnknown() async throws {
    let app = try await SponsorTestEnv.makeApp()
    defer { Task { try? await app.asyncShutdown() } }

    try app.grouped("api", "v1", "sponsor").register(collection: SponsorAPIController())

    try await app.testing().test(
      .GET, "api/v1/sponsor/invitations/not-a-real-token"
    ) { res in
      #expect(res.status == .notFound)
    }
  }

  @Test("GET + POST /api/v1/sponsor/invitations/:token round-trips an invitation")
  func showAndAcceptInvitation() async throws {
    let app = try await SponsorTestEnv.makeApp()
    defer { Task { try? await app.asyncShutdown() } }
    _ = try await SponsorTestEnv.conference(app)
    let (org, owner) = try await SponsorTestEnv.organization(
      app, ownerEmail: "owner@example.com")

    let raw = SecureToken.urlSafe(byteCount: 32)
    let invitation = SponsorInvitation(
      organizationID: try org.requireID(),
      email: "invited@example.com",
      role: .member,
      tokenHash: MagicLinkService.hash(raw),
      expiresAt: Date().addingTimeInterval(86400),
      invitedByUserID: try owner.requireID()
    )
    try await invitation.save(on: app.db)

    try app.grouped("api", "v1", "sponsor").register(collection: SponsorAPIController())

    try await app.testing().test(
      .GET, "api/v1/sponsor/invitations/\(raw)"
    ) { res in
      #expect(res.status == .ok)
      let body = try res.content.decode(InvitationResponseBody.self)
      #expect(body.email == "invited@example.com")
      #expect(body.orgName == "Acme")
    }

    try await app.testing().test(
      .POST, "api/v1/sponsor/invitations/\(raw)/accept"
    ) { res in
      #expect(res.status == .ok)
    }

    let user = try await SponsorUser.query(on: app.db)
      .filter(\.$email == "invited@example.com").first()
    #expect(user != nil)

    let memberships = try await SponsorMembership.query(on: app.db)
      .filter(\.$organization.$id == (try org.requireID()))
      .all()
    #expect(memberships.count == 2)

    let reloaded = try await SponsorInvitation.find(try invitation.requireID(), on: app.db)
    #expect(reloaded?.acceptedAt != nil)
  }

  @Test("POST /api/v1/sponsor/invitations/:token/accept rejects already-used tokens with 410")
  func acceptInvitationGoneAfterUse() async throws {
    let app = try await SponsorTestEnv.makeApp()
    defer { Task { try? await app.asyncShutdown() } }
    _ = try await SponsorTestEnv.conference(app)
    let (org, owner) = try await SponsorTestEnv.organization(
      app, ownerEmail: "owner@example.com")

    let raw = SecureToken.urlSafe(byteCount: 32)
    let invitation = SponsorInvitation(
      organizationID: try org.requireID(),
      email: "invited@example.com",
      role: .member,
      tokenHash: MagicLinkService.hash(raw),
      expiresAt: Date().addingTimeInterval(86400),
      invitedByUserID: try owner.requireID()
    )
    invitation.acceptedAt = Date()
    try await invitation.save(on: app.db)

    try app.grouped("api", "v1", "sponsor").register(collection: SponsorAPIController())

    try await app.testing().test(
      .POST, "api/v1/sponsor/invitations/\(raw)/accept"
    ) { res in
      #expect(res.status == .gone)
    }
  }

  // MARK: - Helper

  private func sponsorCookie(
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
}
