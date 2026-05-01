import Elementary
import Fluent
import Foundation
import SharedModels
import Vapor
import WebSponsor

struct SponsorApplicationController: RouteCollection {
  func boot(routes: RoutesBuilder) throws {
    routes.get("applications", "new", use: renderForm)
    routes.post("applications", use: submit)
    routes.get("applications", ":id", use: detail)
    routes.post("applications", ":id", "withdraw", use: withdraw)
  }

  func renderForm(_ req: Request) async throws -> Response {
    guard req.sponsorUser != nil else { throw Abort(.unauthorized) }
    let conference = try await currentConference(on: req.db)
    let plans = try await SponsorPlan.query(on: req.db)
      .filter(\.$conference.$id == (try conference.requireID()))
      .filter(\.$isActive == true)
      .sort(\.$sortOrder, .ascending)
      .with(\.$localizations)
      .all()
    let dtos = try plans.map { try $0.toDTO() }
    let preselect = req.query[String.self, at: "plan"]
    return try respond(
      ApplicationFormPage(
        locale: req.sponsorLocale, csrfToken: req.csrfToken,
        plans: dtos, preselectedSlug: preselect))
  }

  func submit(_ req: Request) async throws -> Response {
    guard let user = req.sponsorUser else { throw Abort(.unauthorized) }
    let payload = try req.content.decode(SponsorApplicationFormPostPayload.self)
    let acceptedTerms = (payload.acceptedTerms == "true" || payload.acceptedTerms == "on")
    guard acceptedTerms else { throw Abort(.badRequest, reason: "Terms must be accepted") }

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

    let formPayload = SponsorApplicationFormPayload(
      billingContactName: payload.billingContactName,
      billingEmail: payload.billingEmail,
      invoicingNotes: payload.invoicingNotes,
      logoNote: payload.logoNote,
      acceptedTerms: acceptedTerms,
      locale: req.sponsorLocale
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
      .filter(\.$locale == req.sponsorLocale)
      .first())?.name ?? plan.slug

    let mail = SponsorEmailTemplates.render(
      .applicationReceived(planName: planName),
      locale: req.sponsorLocale, recipientName: payload.billingContactName)
    let from =
      Environment.get("RESEND_FROM_EMAIL") ?? "Sponsorship <sponsorship@mail.tryswift.jp>"
    _ = await ResendClient.send(
      to: payload.billingEmail, from: from,
      subject: mail.subject, html: mail.htmlBody, text: mail.textBody,
      client: req.client, logger: req.logger)
    await SponsorSlackNotifier.notifyApplicationSubmitted(
      orgName: membership.organization.displayName, planName: planName,
      client: req.client, logger: req.logger)

    return req.redirect(to: "/applications/\(try application.requireID().uuidString)")
  }

  func detail(_ req: Request) async throws -> Response {
    guard let user = req.sponsorUser else { throw Abort(.unauthorized) }
    guard let id = req.parameters.get("id", as: UUID.self) else { throw Abort(.badRequest) }
    let application = try await SponsorApplication.query(on: req.db)
      .filter(\.$id == id)
      .with(\.$plan) { $0.with(\.$localizations) }
      .first()
    guard let application else { throw Abort(.notFound) }

    let isMember =
      try await SponsorMembership.query(on: req.db)
      .filter(\.$organization.$id == application.$organization.id)
      .filter(\.$user.$id == (try user.requireID()))
      .first() != nil
    guard isMember else { throw Abort(.forbidden) }

    let isOwner =
      try await SponsorMembership.query(on: req.db)
      .filter(\.$organization.$id == application.$organization.id)
      .filter(\.$user.$id == (try user.requireID()))
      .filter(\.$role == .owner)
      .first() != nil
    let canWithdraw = isOwner && application.status == .submitted

    let planName =
      application.plan.localizations
      .first(where: { $0.locale == req.sponsorLocale })?.name ?? application.plan.slug

    return try respond(
      ApplicationDetailPage(
        locale: req.sponsorLocale, csrfToken: req.csrfToken,
        application: try application.toDTO(),
        planName: planName,
        canWithdraw: canWithdraw
      ))
  }

  func withdraw(_ req: Request) async throws -> Response {
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
      throw Abort(.conflict, reason: "Cannot withdraw — already in review")
    }

    application.status = .withdrawn
    try await application.save(on: req.db)
    return req.redirect(to: "/applications/\(id.uuidString)")
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

  private func respond<Page: HTML>(_ page: Page) throws -> Response {
    let html = page.render()
    var headers = HTTPHeaders()
    headers.contentType = .html
    return Response(status: .ok, headers: headers, body: .init(string: html))
  }
}
