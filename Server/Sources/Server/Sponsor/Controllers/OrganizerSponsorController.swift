import Elementary
import Fluent
import Foundation
import SharedModels
import Vapor
import WebSponsor

struct OrganizerSponsorController: RouteCollection {
  func boot(routes: RoutesBuilder) throws {
    routes.get("admin", "sponsors", use: listSponsors)
    routes.get("admin", "sponsors", ":id", use: sponsorDetail)
    routes.get("admin", "inquiries", use: listInquiries)
    routes.get("admin", "applications", use: listApplications)
    routes.get("admin", "applications", ":id", use: applicationDetail)
    routes.post("admin", "applications", ":id", "approve", use: approve)
    routes.post("admin", "applications", ":id", "reject", use: reject)
  }

  func listSponsors(_ req: Request) async throws -> Response {
    let orgs = try await SponsorOrganization.query(on: req.db)
      .with(\.$memberships)
      .with(\.$applications)
      .all()
    let rows: [OrganizerSponsorListPage.Row] = orgs.map { o in
      OrganizerSponsorListPage.Row(
        id: o.id?.uuidString ?? "",
        displayName: o.displayName,
        memberCount: o.memberships.count,
        applicationCount: o.applications.count
      )
    }
    return try respond(OrganizerSponsorListPage(locale: req.sponsorLocale, rows: rows))
  }

  func sponsorDetail(_ req: Request) async throws -> Response {
    guard let id = req.parameters.get("id", as: UUID.self) else { throw Abort(.badRequest) }
    let org = try await SponsorOrganization.query(on: req.db)
      .filter(\.$id == id)
      .with(\.$memberships) { $0.with(\.$user) }
      .with(\.$applications) { $0.with(\.$plan) }
      .first()
    guard let org else { throw Abort(.notFound) }

    let memberEmails = org.memberships.map { $0.user.email }
    let apps: [(id: String, planSlug: String, status: SponsorApplicationStatus)] =
      org.applications.map { app in
        (id: app.id?.uuidString ?? "", planSlug: app.plan.slug, status: app.status)
      }
    return try respond(
      OrganizerSponsorDetailPage(
        locale: req.sponsorLocale,
        organization: try org.toDTO(),
        memberEmails: memberEmails,
        applications: apps
      ))
  }

  func listInquiries(_ req: Request) async throws -> Response {
    let inquiries = try await SponsorInquiry.query(on: req.db)
      .sort(\.$createdAt, .descending)
      .all()
    let dtos = try inquiries.map { try $0.toDTO() }
    return try respond(OrganizerInquiryListPage(locale: req.sponsorLocale, inquiries: dtos))
  }

  func listApplications(_ req: Request) async throws -> Response {
    let applications = try await SponsorApplication.query(on: req.db)
      .with(\.$organization)
      .with(\.$plan)
      .sort(\.$createdAt, .descending)
      .all()
    let rows: [OrganizerApplicationListPage.Row] = applications.map { app in
      OrganizerApplicationListPage.Row(
        id: app.id?.uuidString ?? "",
        orgName: app.organization.displayName,
        planSlug: app.plan.slug,
        status: app.status
      )
    }
    return try respond(OrganizerApplicationListPage(locale: req.sponsorLocale, rows: rows))
  }

  func applicationDetail(_ req: Request) async throws -> Response {
    guard let id = req.parameters.get("id", as: UUID.self) else { throw Abort(.badRequest) }
    let application = try await SponsorApplication.query(on: req.db)
      .filter(\.$id == id)
      .with(\.$organization)
      .with(\.$plan) { $0.with(\.$localizations) }
      .first()
    guard let application else { throw Abort(.notFound) }
    let planName =
      application.plan.localizations
      .first(where: { $0.locale == req.sponsorLocale })?.name ?? application.plan.slug
    return try respond(
      OrganizerApplicationDetailPage(
        locale: req.sponsorLocale, csrfToken: "",
        application: try application.toDTO(),
        orgName: application.organization.displayName,
        planName: planName
      ))
  }

  func approve(_ req: Request) async throws -> Response {
    guard let id = req.parameters.get("id", as: UUID.self) else { throw Abort(.badRequest) }
    guard let payload = req.organizerJWT, let userID = payload.userID else {
      throw Abort(.forbidden)
    }
    _ = try await SponsorApplicationService.approve(
      applicationID: id, decidedByUserID: userID,
      on: req.db, client: req.client, logger: req.logger)
    return req.redirect(to: "/admin/applications/\(id.uuidString)")
  }

  func reject(_ req: Request) async throws -> Response {
    guard let id = req.parameters.get("id", as: UUID.self) else { throw Abort(.badRequest) }
    guard let payload = req.organizerJWT, let userID = payload.userID else {
      throw Abort(.forbidden)
    }
    let body = try req.content.decode(OrganizerRejectPayload.self)
    _ = try await SponsorApplicationService.reject(
      applicationID: id, reason: body.reason, decidedByUserID: userID,
      on: req.db, client: req.client, logger: req.logger)
    return req.redirect(to: "/admin/applications/\(id.uuidString)")
  }

  private func respond<Page: HTML>(_ page: Page) throws -> Response {
    let html = page.render()
    var headers = HTTPHeaders()
    headers.contentType = .html
    return Response(status: .ok, headers: headers, body: .init(string: html))
  }
}
