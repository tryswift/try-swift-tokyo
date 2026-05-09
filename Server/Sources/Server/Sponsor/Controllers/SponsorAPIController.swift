import Fluent
import Foundation
import JWT
import SharedModels
import Vapor

/// JSON endpoints powering the (planned) static sponsor.tryswift.jp portal on
/// Cloudflare Pages. Mounted by `routes.swift` under `/api/v1/sponsor/`.
///
/// Phase 3a/3b ship the public surface:
///   - `GET  /api/v1/sponsor/me`            — auth-state probe; 401 when no cookie
///   - `GET  /api/v1/sponsor/plans`         — public plan list for the LP
///   - `POST /api/v1/sponsor/logout`        — clears the sponsor auth cookie
///   - `POST /api/v1/sponsor/inquiries`     — sponsor inquiry intake; sends magic
///                                            link + materials email, notifies Slack
///   - `POST /api/v1/sponsor/login`         — magic-link issue for an existing user
///   - `GET  /api/v1/sponsor/auth/verify`   — single-use token verify; sets
///                                            `sponsor_auth_token` cookie and
///                                            returns JSON
///
/// Phase 3c adds the sponsor-authenticated application surface:
///   - `GET  /api/v1/sponsor/me/application`        — current latest application
///   - `POST /api/v1/sponsor/applications`          — submit a new application
///   - `GET  /api/v1/sponsor/applications/:id`      — detail (membership-gated)
///   - `POST /api/v1/sponsor/applications/:id/withdraw` — owner-only withdraw
struct SponsorAPIController: RouteCollection {
  func boot(routes: RoutesBuilder) throws {
    routes.get("me", use: me)
    routes.get("plans", use: plans)
    routes.post("logout", use: logout)
    routes.post("inquiries", use: createInquiry)
    routes.post("login", use: requestMagicLink)
    routes.get("auth", "verify", use: verifyMagicLink)

    // Sponsor-authenticated subgroup. We pass `nil` so missing/invalid
    // cookies surface as 401 JSON instead of redirecting to the SSR /login.
    let authed = routes.grouped(SponsorAuthMiddleware(onMissingRedirectTo: nil))
    authed.get("me", "application", use: myApplication)
    authed.post("applications", use: createApplication)
    authed.get("applications", ":id", use: applicationDetail)
    authed.post("applications", ":id", "withdraw", use: withdrawApplication)
  }

  // MARK: - GET /api/v1/sponsor/me

  func me(_ req: Request) async throws -> Response {
    struct MeResponse: Content {
      let id: UUID
      let email: String
      let displayName: String?
      let role: SponsorMemberRole?
      let organization: SponsorOrganizationDTO?
    }

    guard
      let raw = req.cookies[SponsorAuthCookie.name]?.string,
      let payload = try? await req.jwt.verify(raw, as: SponsorJWTPayload.self),
      let userID = payload.sponsorUserID,
      let user = try await SponsorUser.find(userID, on: req.db)
    else {
      throw Abort(.unauthorized)
    }

    var organization: SponsorOrganizationDTO?
    if let orgID = payload.orgID,
      let org = try await SponsorOrganization.find(orgID, on: req.db)
    {
      organization = try org.toDTO()
    }

    let response = Response(status: .ok)
    try response.content.encode(
      MeResponse(
        id: try user.requireID(),
        email: user.email,
        displayName: user.displayName,
        role: payload.role,
        organization: organization
      )
    )
    return response
  }

  // MARK: - GET /api/v1/sponsor/plans

  func plans(_ req: Request) async throws -> Response {
    struct PlansResponse: Content {
      let plans: [SponsorPlanDTO]
    }

    guard
      let conference = try await Conference.query(on: req.db)
        .filter(\.$isAcceptingSponsors == true)
        .sort(\.$year, .descending)
        .first()
    else {
      throw Abort(.serviceUnavailable, reason: "No conference is accepting sponsors")
    }

    let conferenceID = try conference.requireID()
    let plans = try await SponsorPlan.query(on: req.db)
      .filter(\.$conference.$id == conferenceID)
      .filter(\.$isActive == true)
      .sort(\.$sortOrder, .ascending)
      .with(\.$localizations)
      .all()

    let response = Response(status: .ok)
    try response.content.encode(PlansResponse(plans: try plans.map { try $0.toDTO() }))
    return response
  }

  // MARK: - POST /api/v1/sponsor/logout

  func logout(_ req: Request) async throws -> Response {
    let response = Response(status: .ok)
    var cookie = SponsorAuthCookie.make(value: "", ttl: 0)
    cookie.expires = Date(timeIntervalSince1970: 0)
    cookie.maxAge = 0
    response.cookies[SponsorAuthCookie.name] = cookie
    try response.content.encode(["ok": true])
    return response
  }

  // MARK: - POST /api/v1/sponsor/inquiries

  /// Records a SponsorInquiry, finds-or-creates the SponsorUser, sends the
  /// materials email + magic-link login email, and notifies Slack. Returns
  /// `{ok: true}` so the static client can route the user to a thanks view
  /// without depending on a server-issued redirect.
  func createInquiry(_ req: Request) async throws -> Response {
    let payload = try req.content.decode(SponsorInquiryFormPayload.self)
    let locale = inquiryLocale(req)
    guard
      let conference = try await Conference.query(on: req.db)
        .filter(\.$isAcceptingSponsors == true)
        .sort(\.$year, .descending)
        .first()
    else {
      throw Abort(.serviceUnavailable, reason: "No conference is accepting sponsors")
    }

    let inquiry = SponsorInquiry(
      conferenceID: try conference.requireID(),
      companyName: payload.companyName,
      contactName: payload.contactName,
      email: payload.email,
      message: payload.message ?? "",
      locale: locale
    )
    try await inquiry.save(on: req.db)

    let user = try await SponsorPublicController.findOrCreateUser(
      email: payload.email,
      displayName: payload.contactName,
      locale: locale,
      on: req.db
    )

    let issued = try await MagicLinkService.issue(for: user, on: req.db)
    let baseURL = sponsorBaseURL()
    guard let verifyURL = URL(string: "\(baseURL)/auth/verify?token=\(issued.rawToken)") else {
      throw Abort(.internalServerError, reason: "Invalid SPONSOR_BASE_URL")
    }
    let materialsURL =
      URL(
        string: Environment.get("SPONSOR_MATERIALS_URL")
          ?? "\(baseURL)/sponsor/materials/sponsor-pack-2026.pdf") ?? verifyURL
    let from = Environment.get("RESEND_FROM_EMAIL") ?? "Sponsorship <sponsorship@mail.tryswift.jp>"

    let mat = SponsorEmailTemplates.render(
      .inquiryReceived(materialsURL: materialsURL),
      locale: locale,
      recipientName: payload.contactName)
    _ = await ResendClient.send(
      to: payload.email,
      from: from,
      subject: mat.subject,
      html: mat.htmlBody,
      text: mat.textBody,
      client: req.client,
      logger: req.logger)

    let login = SponsorEmailTemplates.render(
      .magicLink(verifyURL: verifyURL, ttlMinutes: 30),
      locale: locale,
      recipientName: payload.contactName)
    _ = await ResendClient.send(
      to: payload.email,
      from: from,
      subject: login.subject,
      html: login.htmlBody,
      text: login.textBody,
      client: req.client,
      logger: req.logger)

    await SponsorSlackNotifier.notifyInquiry(
      companyName: payload.companyName,
      planSlug: nil,
      client: req.client,
      logger: req.logger)

    let response = Response(status: .ok)
    try response.content.encode(["ok": true])
    return response
  }

  // MARK: - POST /api/v1/sponsor/login

  /// Issues a magic-link email for an existing SponsorUser. Always returns
  /// `{ok: true}` regardless of whether the email matched, so the response
  /// shape doesn't leak which addresses are registered.
  func requestMagicLink(_ req: Request) async throws -> Response {
    let payload = try req.content.decode(MagicLinkRequestPayload.self)
    if let user = try await SponsorUser.query(on: req.db)
      .filter(\.$email == payload.email.lowercased()).first()
    {
      let issued = try await MagicLinkService.issue(for: user, on: req.db)
      let baseURL = sponsorBaseURL()
      if let url = URL(string: "\(baseURL)/auth/verify?token=\(issued.rawToken)") {
        let from =
          Environment.get("RESEND_FROM_EMAIL") ?? "Sponsorship <sponsorship@mail.tryswift.jp>"
        let mail = SponsorEmailTemplates.render(
          .magicLink(verifyURL: url, ttlMinutes: 30),
          locale: user.locale,
          recipientName: user.displayName)
        _ = await ResendClient.send(
          to: user.email,
          from: from,
          subject: mail.subject,
          html: mail.htmlBody,
          text: mail.textBody,
          client: req.client,
          logger: req.logger)
      }
    }
    let response = Response(status: .ok)
    try response.content.encode(["ok": true])
    return response
  }

  // MARK: - GET /api/v1/sponsor/auth/verify

  /// Verifies a single-use magic-link token, mints a sponsor JWT, and sets
  /// the `sponsor_auth_token` cookie. Returns JSON describing the resulting
  /// session so the static client can decide where to navigate.
  func verifyMagicLink(_ req: Request) async throws -> Response {
    struct VerifyResponse: Content {
      let id: UUID
      let email: String
      let role: SponsorMemberRole?
      let organization: SponsorOrganizationDTO?
    }

    let token = try req.query.get(String.self, at: "token")
    guard let user = try await MagicLinkService.verify(rawToken: token, on: req.db) else {
      throw Abort(.unauthorized, reason: "Invalid or expired token")
    }
    let membership = try await SponsorMembership.query(on: req.db)
      .filter(\.$user.$id == (try user.requireID()))
      .first()

    let jwtPayload = SponsorJWTPayload(
      userID: try user.requireID(),
      orgID: membership?.$organization.id,
      role: membership?.role,
      locale: user.locale
    )
    let signed = try await req.jwt.sign(jwtPayload)

    var organization: SponsorOrganizationDTO?
    if let orgID = membership?.$organization.id,
      let org = try await SponsorOrganization.find(orgID, on: req.db)
    {
      organization = try org.toDTO()
    }

    let response = Response(status: .ok)
    response.cookies[SponsorAuthCookie.name] = SponsorAuthCookie.make(value: signed)
    try response.content.encode(
      VerifyResponse(
        id: try user.requireID(),
        email: user.email,
        role: membership?.role,
        organization: organization
      )
    )
    return response
  }

  // MARK: - GET /api/v1/sponsor/me/application

  /// Returns the currently-signed-in sponsor user's latest application for
  /// the active conference, or 404 if they have not yet applied.
  func myApplication(_ req: Request) async throws -> Response {
    guard let user = req.sponsorUser else { throw Abort(.unauthorized) }

    guard
      let membership = try await SponsorMembership.query(on: req.db)
        .filter(\.$user.$id == (try user.requireID()))
        .first()
    else { throw Abort(.notFound) }

    let conference = try await currentConference(on: req.db)
    guard
      let application = try await SponsorApplication.query(on: req.db)
        .filter(\.$organization.$id == membership.$organization.id)
        .filter(\.$conference.$id == (try conference.requireID()))
        .sort(\.$createdAt, .descending)
        .first()
    else { throw Abort(.notFound) }

    let response = Response(status: .ok)
    try response.content.encode(try application.toDTO())
    return response
  }

  // MARK: - POST /api/v1/sponsor/applications

  /// JSON-friendly application intake. Mirrors the SSR form-post flow but
  /// expects `acceptedTerms: Bool` instead of the form-encoded "true"/"on"
  /// string the SSR controller has to coerce.
  func createApplication(_ req: Request) async throws -> Response {
    struct CreatePayload: Content {
      let planSlug: String
      let billingContactName: String
      let billingEmail: String
      let invoicingNotes: String?
      let logoNote: String?
      let acceptedTerms: Bool
    }

    guard let user = req.sponsorUser else { throw Abort(.unauthorized) }
    let payload = try req.content.decode(CreatePayload.self)
    guard payload.acceptedTerms else {
      throw Abort(.badRequest, reason: "Terms must be accepted")
    }

    guard
      let membership = try await SponsorMembership.query(on: req.db)
        .filter(\.$user.$id == (try user.requireID()))
        .with(\.$organization)
        .first()
    else { throw Abort(.forbidden, reason: "No organization") }

    let conference = try await currentConference(on: req.db)
    guard
      let plan = try await SponsorPlan.query(on: req.db)
        .filter(\.$conference.$id == (try conference.requireID()))
        .filter(\.$slug == payload.planSlug)
        .first()
    else { throw Abort(.notFound, reason: "Plan not found") }

    let locale = req.sponsorJWT?.locale ?? user.locale
    let formPayload = SponsorApplicationFormPayload(
      billingContactName: payload.billingContactName,
      billingEmail: payload.billingEmail,
      invoicingNotes: payload.invoicingNotes,
      logoNote: payload.logoNote,
      acceptedTerms: payload.acceptedTerms,
      locale: locale
    )
    let application = SponsorApplication(
      organizationID: try membership.organization.requireID(),
      planID: try plan.requireID(),
      conferenceID: try conference.requireID(),
      status: .submitted,
      payload: formPayload,
      submittedAt: Date()
    )
    try await application.save(on: req.db)

    let planName =
      (try await SponsorPlanLocalization.query(on: req.db)
      .filter(\.$plan.$id == (try plan.requireID()))
      .filter(\.$locale == locale)
      .first())?.name ?? plan.slug

    let mail = SponsorEmailTemplates.render(
      .applicationReceived(planName: planName),
      locale: locale, recipientName: payload.billingContactName)
    let from =
      Environment.get("RESEND_FROM_EMAIL") ?? "Sponsorship <sponsorship@mail.tryswift.jp>"
    _ = await ResendClient.send(
      to: payload.billingEmail, from: from,
      subject: mail.subject, html: mail.htmlBody, text: mail.textBody,
      client: req.client, logger: req.logger)
    await SponsorSlackNotifier.notifyApplicationSubmitted(
      orgName: membership.organization.displayName, planName: planName,
      client: req.client, logger: req.logger)

    let response = Response(status: .created)
    try response.content.encode(try application.toDTO())
    return response
  }

  // MARK: - GET /api/v1/sponsor/applications/:id

  /// Returns one application's details if the caller is a member of the
  /// owning organization. Includes a `canWithdraw` hint so the client can
  /// gate the withdraw button without a second request.
  func applicationDetail(_ req: Request) async throws -> Response {
    struct DetailResponse: Content {
      let application: SponsorApplicationDTO
      let planName: String
      let canWithdraw: Bool
    }

    guard let user = req.sponsorUser else { throw Abort(.unauthorized) }
    guard let id = req.parameters.get("id", as: UUID.self) else { throw Abort(.badRequest) }

    let application = try await SponsorApplication.query(on: req.db)
      .filter(\.$id == id)
      .with(\.$plan) { $0.with(\.$localizations) }
      .first()
    guard let application else { throw Abort(.notFound) }

    let memberships = try await SponsorMembership.query(on: req.db)
      .filter(\.$organization.$id == application.$organization.id)
      .filter(\.$user.$id == (try user.requireID()))
      .all()
    guard !memberships.isEmpty else { throw Abort(.forbidden) }

    let isOwner = memberships.contains { $0.role == .owner }
    let canWithdraw = isOwner && application.status == .submitted

    let locale = req.sponsorJWT?.locale ?? user.locale
    let planName =
      application.plan.localizations
      .first(where: { $0.locale == locale })?.name ?? application.plan.slug

    let response = Response(status: .ok)
    try response.content.encode(
      DetailResponse(
        application: try application.toDTO(),
        planName: planName,
        canWithdraw: canWithdraw
      )
    )
    return response
  }

  // MARK: - POST /api/v1/sponsor/applications/:id/withdraw

  /// Owners can withdraw an application that is still in `.submitted`. Any
  /// other status (already in review, approved, etc.) returns 409 to signal
  /// the operation is no longer valid.
  func withdrawApplication(_ req: Request) async throws -> Response {
    guard let user = req.sponsorUser else { throw Abort(.unauthorized) }
    guard let id = req.parameters.get("id", as: UUID.self) else { throw Abort(.badRequest) }
    guard let application = try await SponsorApplication.find(id, on: req.db)
    else { throw Abort(.notFound) }

    let isOwner =
      try await SponsorMembership.query(on: req.db)
      .filter(\.$organization.$id == application.$organization.id)
      .filter(\.$user.$id == (try user.requireID()))
      .filter(\.$role == .owner)
      .first() != nil
    guard isOwner else { throw Abort(.forbidden) }
    guard application.status == .submitted else {
      throw Abort(
        .conflict,
        reason: "Cannot withdraw an application in status: \(application.status.rawValue)"
      )
    }

    application.status = .withdrawn
    try await application.save(on: req.db)

    let response = Response(status: .ok)
    try response.content.encode(try application.toDTO())
    return response
  }

  // MARK: - Helpers

  private func sponsorBaseURL() -> String {
    Environment.get("SPONSOR_BASE_URL") ?? "https://sponsor.tryswift.jp"
  }

  private func inquiryLocale(_ req: Request) -> SponsorPortalLocale {
    SponsorPortalLocale(rawValue: req.headers.first(name: "X-Locale") ?? "") ?? .ja
  }

  private func currentConference(on db: Database) async throws -> Conference {
    guard
      let conference = try await Conference.query(on: db)
        .filter(\.$isAcceptingSponsors == true)
        .sort(\.$year, .descending)
        .first()
    else {
      throw Abort(.serviceUnavailable, reason: "No conference is accepting sponsors")
    }
    return conference
  }
}
