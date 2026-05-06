import Elementary
import Fluent
import Foundation
import SharedModels
import Vapor
import WebScholarship

/// Organizer (admin) routes for the scholarship portal. Authentication is
/// handled by the shared `OrganizerOnlyMiddleware` (auth_token cookie + admin
/// role on the GitHub User table); this controller only worries about the
/// page-level logic.
struct OrganizerScholarshipController: RouteCollection {
  func boot(routes: RoutesBuilder) throws {
    let organizer = routes.grouped("organizer")
    organizer.get(use: list)
    organizer.get("budget", use: budgetPage)
    organizer.post("budget", use: saveBudget)
    organizer.get("export", use: exportCSV)
    organizer.get(":id", use: detail)
    organizer.post(":id", "approve", use: approve)
    organizer.post(":id", "reject", use: reject)
    organizer.post(":id", "revert", use: revert)
  }

  // MARK: List

  func list(_ req: Request) async throws -> Response {
    let conference = try await currentConference(on: req.db)
    var dtos: [ScholarshipApplicationDTO] = []
    var summary: ScholarshipBudgetSummaryDTO?
    if let conference {
      let conferenceID = try conference.requireID()
      let applications = try await ScholarshipApplication.query(on: req.db)
        .filter(\.$conference.$id == conferenceID)
        .sort(\.$createdAt, .descending)
        .all()
      dtos = try applications.map { try $0.toDTO(conference: conference) }
      let budget = try await ScholarshipBudget.query(on: req.db)
        .filter(\.$conference.$id == conferenceID)
        .first()
      let approved = applications.filter { $0.status == .approved }
        .reduce(0) { $0 + ($1.approvedAmount ?? 0) }
      summary = ScholarshipBudgetSummaryDTO(
        totalBudget: budget?.totalBudget,
        approvedTotal: approved
      )
    }
    return respond(
      ApplicationListPage(
        locale: req.studentLocale,
        applications: dtos,
        budget: summary
      )
    )
  }

  // MARK: Detail

  func detail(_ req: Request) async throws -> Response {
    guard let id = req.parameters.get("id", as: UUID.self) else { throw Abort(.badRequest) }
    let application = try await ScholarshipApplication.query(on: req.db)
      .filter(\.$id == id)
      .with(\.$conference)
      .first()
    guard let application else { throw Abort(.notFound) }
    let dto = try application.toDTO(conference: application.conference)
    return respond(
      ApplicationDetailPage(
        locale: req.studentLocale,
        csrfToken: req.csrfToken,
        application: dto
      )
    )
  }

  // MARK: Approve / reject / revert

  func approve(_ req: Request) async throws -> Response {
    guard let id = req.parameters.get("id", as: UUID.self) else { throw Abort(.badRequest) }
    let payload = try req.content.decode(ScholarshipApproveActionPayload.self)
    let application = try await ScholarshipApplication.query(on: req.db)
      .filter(\.$id == id)
      .with(\.$applicant)
      .with(\.$conference)
      .first()
    guard let application else { throw Abort(.notFound) }

    application.status = .approved
    application.approvedAmount = payload.approvedAmount
    application.organizerNotes = payload.organizerNotes
    try await application.save(on: req.db)

    let locale = ScholarshipPortalLocale(rawValue: application.languagePreference) ?? .default
    let mail = ScholarshipEmailTemplates.render(
      .applicationApproved(
        conferenceName: application.conference.displayName,
        approvedAmountYen: payload.approvedAmount
      ),
      locale: locale,
      recipientName: application.name
    )
    let from = Environment.get("RESEND_FROM_EMAIL") ?? "Scholarship <scholarship@mail.tryswift.jp>"
    _ = await ResendClient.send(
      to: application.email, from: from,
      subject: mail.subject, html: mail.htmlBody, text: mail.textBody,
      client: req.client, logger: req.logger
    )
    await ScholarshipSlackNotifier.notifyDecision(
      name: application.name,
      school: application.schoolAndFaculty,
      decision: "Approved",
      approvedAmount: payload.approvedAmount,
      client: req.client,
      logger: req.logger
    )

    return req.redirect(to: "/organizer/\(id.uuidString)")
  }

  func reject(_ req: Request) async throws -> Response {
    guard let id = req.parameters.get("id", as: UUID.self) else { throw Abort(.badRequest) }
    let payload = try req.content.decode(ScholarshipRejectActionPayload.self)
    let application = try await ScholarshipApplication.query(on: req.db)
      .filter(\.$id == id)
      .with(\.$conference)
      .first()
    guard let application else { throw Abort(.notFound) }

    application.status = .rejected
    application.organizerNotes = payload.organizerNotes
    try await application.save(on: req.db)

    let locale = ScholarshipPortalLocale(rawValue: application.languagePreference) ?? .default
    let mail = ScholarshipEmailTemplates.render(
      .applicationRejected(
        conferenceName: application.conference.displayName,
        reason: payload.organizerNotes
      ),
      locale: locale,
      recipientName: application.name
    )
    let from = Environment.get("RESEND_FROM_EMAIL") ?? "Scholarship <scholarship@mail.tryswift.jp>"
    _ = await ResendClient.send(
      to: application.email, from: from,
      subject: mail.subject, html: mail.htmlBody, text: mail.textBody,
      client: req.client, logger: req.logger
    )
    await ScholarshipSlackNotifier.notifyDecision(
      name: application.name,
      school: application.schoolAndFaculty,
      decision: "Rejected",
      client: req.client,
      logger: req.logger
    )

    return req.redirect(to: "/organizer/\(id.uuidString)")
  }

  func revert(_ req: Request) async throws -> Response {
    guard let id = req.parameters.get("id", as: UUID.self) else { throw Abort(.badRequest) }
    guard let application = try await ScholarshipApplication.find(id, on: req.db)
    else { throw Abort(.notFound) }
    application.status = .submitted
    application.approvedAmount = nil
    try await application.save(on: req.db)
    return req.redirect(to: "/organizer/\(id.uuidString)")
  }

  // MARK: Budget

  func budgetPage(_ req: Request) async throws -> Response {
    let conference = try await currentConference(on: req.db)
    var budgetDTO: ScholarshipBudgetDTO?
    var summary: ScholarshipBudgetSummaryDTO?
    if let conference {
      let conferenceID = try conference.requireID()
      let budget = try await ScholarshipBudget.query(on: req.db)
        .filter(\.$conference.$id == conferenceID)
        .first()
      budgetDTO = try budget?.toDTO()
      let applications = try await ScholarshipApplication.query(on: req.db)
        .filter(\.$conference.$id == conferenceID)
        .all()
      let approved = applications.filter { $0.status == .approved }
        .reduce(0) { $0 + ($1.approvedAmount ?? 0) }
      summary = ScholarshipBudgetSummaryDTO(
        totalBudget: budget?.totalBudget,
        approvedTotal: approved
      )
    }
    return respond(
      BudgetPage(
        locale: req.studentLocale,
        csrfToken: req.csrfToken,
        budget: budgetDTO,
        summary: summary
      )
    )
  }

  func saveBudget(_ req: Request) async throws -> Response {
    let payload = try req.content.decode(ScholarshipBudgetUpdatePayload.self)
    guard let conference = try await currentConference(on: req.db) else {
      throw Abort(.serviceUnavailable, reason: "No conference accepting applications")
    }
    let conferenceID = try conference.requireID()
    if let existing = try await ScholarshipBudget.query(on: req.db)
      .filter(\.$conference.$id == conferenceID)
      .first()
    {
      existing.totalBudget = payload.totalBudget
      existing.notes = payload.notes
      try await existing.save(on: req.db)
    } else {
      let budget = ScholarshipBudget(
        conferenceID: conferenceID,
        totalBudget: payload.totalBudget,
        notes: payload.notes
      )
      try await budget.save(on: req.db)
    }
    return req.redirect(to: "/organizer/budget")
  }

  // MARK: CSV export

  func exportCSV(_ req: Request) async throws -> Response {
    guard let conference = try await currentConference(on: req.db) else {
      throw Abort(.serviceUnavailable, reason: "No conference accepting applications")
    }
    let applications = try await ScholarshipApplication.query(on: req.db)
      .filter(\.$conference.$id == (try conference.requireID()))
      .sort(\.$createdAt, .descending)
      .all()

    let header = [
      "id", "created_at", "status", "name", "email", "school_and_faculty",
      "current_year", "support_type", "approved_amount", "desired_support_amount",
      "total_estimated_cost", "language_preference", "purposes",
    ]
    var rows: [[String]] = [header]
    for app in applications {
      rows.append([
        app.id?.uuidString ?? "",
        app.createdAt.map { ISO8601DateFormatter().string(from: $0) } ?? "",
        app.status.rawValue,
        app.name,
        app.email,
        app.schoolAndFaculty,
        app.currentYear,
        app.supportType.rawValue,
        app.approvedAmount.map { String($0) } ?? "",
        app.desiredSupportAmount.map { String($0) } ?? "",
        app.totalEstimatedCost.map { String($0) } ?? "",
        app.languagePreference,
        app.purposes.items.joined(separator: "|"),
      ])
    }
    let csv =
      rows
      .map { row in row.map(escapeCSV).joined(separator: ",") }
      .joined(separator: "\r\n")

    var headers = HTTPHeaders()
    headers.add(name: .contentType, value: "text/csv; charset=utf-8")
    headers.add(
      name: .contentDisposition,
      value: "attachment; filename=\"scholarship-applications.csv\""
    )
    return Response(status: .ok, headers: headers, body: .init(string: csv))
  }

  // MARK: Helpers

  private func currentConference(on db: Database) async throws -> Conference? {
    try await Conference.query(on: db)
      .sort(\.$year, .descending)
      .first()
  }

  private func respond<Page: HTML>(_ page: Page) -> Response {
    let html = page.render()
    var headers = HTTPHeaders()
    headers.contentType = .html
    return Response(status: .ok, headers: headers, body: .init(string: html))
  }

  /// Escape a CSV cell. Prefixes a single quote when the value would
  /// otherwise be interpreted as a formula (`=`, `+`, `-`, `@`) and quotes
  /// fields that contain commas, quotes, or newlines.
  private func escapeCSV(_ value: String) -> String {
    var v = value
    if let first = v.first, "=+-@".contains(first) {
      v = "'" + v
    }
    let needsQuotes = v.contains(",") || v.contains("\"") || v.contains("\n") || v.contains("\r")
    if needsQuotes {
      let escaped = v.replacingOccurrences(of: "\"", with: "\"\"")
      return "\"\(escaped)\""
    }
    return v
  }
}
