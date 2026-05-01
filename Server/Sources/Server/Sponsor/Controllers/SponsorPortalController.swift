import Elementary
import Fluent
import Foundation
import JWT
import SharedModels
import Vapor
import WebSponsor

struct SponsorPortalController: RouteCollection {
  func boot(routes: RoutesBuilder) throws {
    routes.get("dashboard", use: dashboard)
    routes.get("profile", use: renderProfile)
    routes.post("profile", use: updateProfile)
    routes.get("team", use: renderTeam)
    routes.post("team", "invite", use: invite)
    routes.post("team", ":userID", "remove", use: removeMember)
    routes.get("invitations", ":token", use: renderAcceptInvitation)
    routes.post("invitations", ":token", "accept", use: acceptInvitation)
  }

  // MARK: - Dashboard

  func dashboard(_ req: Request) async throws -> Response {
    guard let user = req.sponsorUser else { throw Abort(.unauthorized) }
    let orgName = try await currentOrganization(for: user, on: req.db)?.displayName
    return respond(
      DashboardPage(locale: req.sponsorLocale, userEmail: user.email, orgName: orgName))
  }

  // MARK: - Profile

  func renderProfile(_ req: Request) async throws -> Response {
    guard let user = req.sponsorUser else { throw Abort(.unauthorized) }
    let (org, isOwner) = try await currentMembership(for: user, on: req.db)
    return respond(
      ProfilePage(
        locale: req.sponsorLocale, csrfToken: req.csrfToken,
        legalName: org?.legalName ?? "",
        displayName: org?.displayName ?? "",
        country: org?.country ?? "",
        billingAddress: org?.billingAddress ?? "",
        websiteURL: org?.websiteURL ?? "",
        isOwner: isOwner
      ))
  }

  func updateProfile(_ req: Request) async throws -> Response {
    guard let user = req.sponsorUser else { throw Abort(.unauthorized) }
    let payload = try req.content.decode(SponsorProfileUpdatePayload.self)
    let (existing, isOwner) = try await currentMembership(for: user, on: req.db)
    if let existing {
      guard isOwner else { throw Abort(.forbidden) }
      existing.legalName = payload.legalName
      existing.displayName = payload.displayName
      existing.country = payload.country
      existing.billingAddress = payload.billingAddress
      existing.websiteURL = payload.websiteURL
      try await existing.save(on: req.db)
    } else {
      let org = SponsorOrganization(
        legalName: payload.legalName, displayName: payload.displayName,
        country: payload.country, billingAddress: payload.billingAddress,
        websiteURL: payload.websiteURL
      )
      try await org.save(on: req.db)
      let mem = SponsorMembership(
        organizationID: try org.requireID(),
        userID: try user.requireID(),
        role: .owner
      )
      try await mem.save(on: req.db)
    }
    return req.redirect(to: "/profile")
  }

  // MARK: - Team

  func renderTeam(_ req: Request) async throws -> Response {
    guard let user = req.sponsorUser else { throw Abort(.unauthorized) }
    let (org, isOwner) = try await currentMembership(for: user, on: req.db)
    var rows: [MembersPage.MemberRow] = []
    if let org {
      let memberships = try await SponsorMembership.query(on: req.db)
        .filter(\.$organization.$id == (try org.requireID()))
        .with(\.$user)
        .all()
      rows = memberships.map { m in
        MembersPage.MemberRow(
          userID: m.$user.id.uuidString,
          email: m.user.email,
          role: m.role
        )
      }
    }
    return respond(
      MembersPage(
        locale: req.sponsorLocale, csrfToken: req.csrfToken,
        members: rows, isOwner: isOwner))
  }

  func invite(_ req: Request) async throws -> Response {
    guard let user = req.sponsorUser else { throw Abort(.unauthorized) }
    let payload = try req.content.decode(SponsorTeamInvitePayload.self)
    let (org, isOwner) = try await currentMembership(for: user, on: req.db)
    guard let org, isOwner else { throw Abort(.forbidden) }

    let raw = randomURLSafeToken(byteCount: 32)
    let hashed = MagicLinkService.hash(raw)
    let invitation = SponsorInvitation(
      organizationID: try org.requireID(),
      email: payload.email,
      role: .member,
      tokenHash: hashed,
      expiresAt: Date().addingTimeInterval(86400 * 7),
      invitedByUserID: try user.requireID()
    )
    try await invitation.save(on: req.db)

    let baseURL = Environment.get("SPONSOR_BASE_URL") ?? "https://sponsor.tryswift.jp"
    let acceptURL = URL(string: "\(baseURL)/invitations/\(raw)")!
    let mail = SponsorEmailTemplates.render(
      .memberInvite(
        orgName: org.displayName,
        inviterName: user.displayName ?? user.email,
        acceptURL: acceptURL),
      locale: req.sponsorLocale, recipientName: nil)
    let from =
      Environment.get("RESEND_FROM_EMAIL") ?? "Sponsorship <sponsorship@mail.tryswift.jp>"
    _ = await ResendClient.send(
      to: payload.email, from: from,
      subject: mail.subject, html: mail.htmlBody, text: mail.textBody,
      client: req.client, logger: req.logger)
    return req.redirect(to: "/team")
  }

  func removeMember(_ req: Request) async throws -> Response {
    guard let user = req.sponsorUser else { throw Abort(.unauthorized) }
    guard let targetUserID = req.parameters.get("userID", as: UUID.self) else {
      throw Abort(.badRequest)
    }
    let (org, isOwner) = try await currentMembership(for: user, on: req.db)
    guard let org, isOwner else { throw Abort(.forbidden) }
    if targetUserID == user.id {
      throw Abort(.badRequest, reason: "Owner cannot remove themselves")
    }
    try await SponsorMembership.query(on: req.db)
      .filter(\.$organization.$id == (try org.requireID()))
      .filter(\.$user.$id == targetUserID)
      .delete()
    return req.redirect(to: "/team")
  }

  // MARK: - Invitations

  func renderAcceptInvitation(_ req: Request) async throws -> Response {
    guard let token = req.parameters.get("token") else { throw Abort(.badRequest) }
    let hashed = MagicLinkService.hash(token)
    guard
      let invitation = try await SponsorInvitation.query(on: req.db)
        .filter(\.$tokenHash == hashed)
        .with(\.$organization)
        .first()
    else { throw Abort(.notFound) }
    if invitation.acceptedAt != nil || invitation.expiresAt < Date() {
      throw Abort(.gone, reason: "Invitation already used or expired")
    }
    return respond(
      InvitationAcceptPage(
        locale: req.sponsorLocale,
        orgName: invitation.organization.displayName,
        token: token))
  }

  func acceptInvitation(_ req: Request) async throws -> Response {
    guard let token = req.parameters.get("token") else { throw Abort(.badRequest) }
    let hashed = MagicLinkService.hash(token)
    guard
      let invitation = try await SponsorInvitation.query(on: req.db)
        .filter(\.$tokenHash == hashed)
        .first()
    else { throw Abort(.notFound) }
    if invitation.acceptedAt != nil || invitation.expiresAt < Date() {
      throw Abort(.gone)
    }

    let user = try await SponsorPublicController.findOrCreateUser(
      email: invitation.email, displayName: nil,
      locale: req.sponsorLocale, on: req.db
    )

    if try await SponsorMembership.query(on: req.db)
      .filter(\.$organization.$id == invitation.$organization.id)
      .filter(\.$user.$id == (try user.requireID()))
      .first() == nil
    {
      let mem = SponsorMembership(
        organizationID: invitation.$organization.id,
        userID: try user.requireID(),
        role: invitation.role,
        invitedByUserID: invitation.invitedByUserID
      )
      try await mem.save(on: req.db)
    }

    invitation.acceptedAt = Date()
    try await invitation.save(on: req.db)

    // Issue magic-link to log the new user in
    let issued = try await MagicLinkService.issue(for: user, on: req.db)
    let baseURL = Environment.get("SPONSOR_BASE_URL") ?? "https://sponsor.tryswift.jp"
    let url = URL(string: "\(baseURL)/auth/verify?token=\(issued.rawToken)")!
    let mail = SponsorEmailTemplates.render(
      .magicLink(verifyURL: url, ttlMinutes: 30),
      locale: user.locale, recipientName: user.displayName)
    let from = Environment.get("RESEND_FROM_EMAIL") ?? "Sponsorship <sponsorship@mail.tryswift.jp>"
    _ = await ResendClient.send(
      to: user.email, from: from,
      subject: mail.subject, html: mail.htmlBody, text: mail.textBody,
      client: req.client, logger: req.logger)
    return req.redirect(to: "/login/sent")
  }

  // MARK: - Helpers

  private func currentOrganization(for user: SponsorUser, on db: Database) async throws
    -> SponsorOrganization?
  {
    try await SponsorMembership.query(on: db)
      .filter(\.$user.$id == (try user.requireID()))
      .with(\.$organization)
      .first()?.organization
  }

  private func currentMembership(for user: SponsorUser, on db: Database) async throws
    -> (SponsorOrganization?, Bool)
  {
    if let mem = try await SponsorMembership.query(on: db)
      .filter(\.$user.$id == (try user.requireID()))
      .with(\.$organization)
      .first()
    {
      return (mem.organization, mem.role == .owner)
    }
    return (nil, false)
  }

  private func randomURLSafeToken(byteCount: Int) -> String {
    SecureToken.urlSafe(byteCount: byteCount)
  }

  private func respond<Page: HTML>(_ page: Page) -> Response {
    let html = page.render()
    var headers = HTTPHeaders()
    headers.contentType = .html
    return Response(status: .ok, headers: headers, body: .init(string: html))
  }
}
