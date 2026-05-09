import Fluent
import Foundation
import JWT
import SharedModels
import Vapor

/// JSON endpoints powering the (planned) static sponsor.tryswift.jp portal on
/// Cloudflare Pages. Mounted by `routes.swift` under `/api/v1/sponsor/`.
///
/// Phase 3a ships the read-only public endpoints only:
///   - `GET /api/v1/sponsor/me`     — auth-state probe; 401 when no cookie
///   - `GET /api/v1/sponsor/plans`  — public plan list for the LP
///   - `POST /api/v1/sponsor/logout` — clears the sponsor auth cookie
///
/// Inquiry intake, magic-link issue/verify, and the sponsor + organizer
/// authenticated endpoints land in subsequent PRs (Phase 3b/3c).
struct SponsorAPIController: RouteCollection {
  func boot(routes: RoutesBuilder) throws {
    routes.get("me", use: me)
    routes.get("plans", use: plans)
    routes.post("logout", use: logout)
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
}
