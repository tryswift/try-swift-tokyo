import Fluent
import Foundation
import JWT
import SharedModels
import Vapor

/// JSON / redirect-handling endpoints powering the static student.tryswift.jp
/// portal. Mounted by `routes.swift` under `/api/v1/scholarship/`, e.g.
/// `POST /api/v1/scholarship/login`. Public reads return JSON, form POSTs
/// answer with 303 redirects back to the static portal so the browser lands
/// on the right page after submission.
struct ScholarshipAPIController: RouteCollection {
  func boot(routes: RoutesBuilder) throws {
    // Public.
    routes.get("info", use: info)
    routes.get("me", use: me)
    routes.post("login", use: requestMagicLink)
    routes.get("auth", "verify", use: verifyMagicLink)
    routes.post("logout", use: logout)
    routes.get("api", "travel-cost", use: travelCost)

    // Applicant (auth required).
    let applicant = routes.grouped(StudentAuthMiddleware(onMissingRedirectTo: nil))
    applicant.post("apply", use: submit)
    applicant.get("me", "application", use: myApplication)
    applicant.post("me", "application", "withdraw", use: withdraw)

    // Organizer (admin auth required).
    let organizer = routes.grouped(ScholarshipOrganizerAuthMiddleware())
    organizer.get("organizer", "applications", use: organizerList)
    organizer.get("organizer", "applications.csv", use: organizerCSV)
    organizer.get("organizer", "applications", ":id", use: organizerDetail)
    organizer.post("organizer", "applications", ":id", "approve", use: organizerApprove)
    organizer.post("organizer", "applications", ":id", "reject", use: organizerReject)
    organizer.post("organizer", "applications", ":id", "revert", use: organizerRevert)
    organizer.get("organizer", "budget", use: organizerBudget)
    organizer.post("organizer", "budget", use: organizerSaveBudget)
  }

  // MARK: - Public JSON endpoints

  func info(_ req: Request) async throws -> Response {
    struct InfoResponse: Content {
      let conferenceDisplayName: String?
      let budget: ScholarshipBudgetSummaryDTO?
    }
    let conference = try await currentConference(on: req.db)
    var summary: ScholarshipBudgetSummaryDTO?
    if let conference {
      let conferenceID = try conference.requireID()
      let budget = try await ScholarshipBudget.query(on: req.db)
        .filter(\.$conference.$id == conferenceID).first()
      let approved = try await approvedTotal(conferenceID: conferenceID, on: req.db)
      summary = ScholarshipBudgetSummaryDTO(
        totalBudget: budget?.totalBudget, approvedTotal: approved)
    }
    let response = Response(status: .ok)
    try response.content.encode(
      InfoResponse(conferenceDisplayName: conference?.displayName, budget: summary))
    return response
  }

  func me(_ req: Request) async throws -> Response {
    struct MeResponse: Content {
      let id: UUID
      let email: String
      let displayName: String?
      let isOrganizer: Bool
    }
    guard let raw = req.cookies[StudentAuthCookie.name]?.string,
      let payload = try? await req.jwt.verify(raw, as: StudentJWTPayload.self),
      let userID = payload.studentUserID,
      let user = try await StudentUser.find(userID, on: req.db)
    else {
      throw Abort(.unauthorized)
    }
    let isOrganizer = await isOrganizerSession(req)
    let response = Response(status: .ok)
    try response.content.encode(
      MeResponse(
        id: try user.requireID(),
        email: user.email,
        displayName: user.displayName,
        isOrganizer: isOrganizer
      )
    )
    return response
  }

  func requestMagicLink(_ req: Request) async throws -> Response {
    struct LoginPayload: Content {
      let email: String
      let redirect_to: String?
    }
    let payload = try req.content.decode(LoginPayload.self)
    let trimmed = payload.email.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { throw Abort(.badRequest, reason: "Email required") }

    let locale =
      ScholarshipPortalLocale(rawValue: req.headers.first(name: "X-Locale") ?? "")
      ?? .default
    let user = try await findOrCreateUser(email: trimmed, on: req.db, locale: locale)
    let issued = try await ScholarshipMagicLinkService.issue(for: user, on: req.db)

    let studentBase = studentBaseURL()
    let apiBase = apiBaseURL()
    guard
      let verifyURL = URL(
        string: "\(apiBase)/api/v1/scholarship/auth/verify?token=\(issued.rawToken)"
          + (payload.redirect_to.map {
            "&redirect_to=\($0.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
          } ?? "")
      )
    else {
      throw Abort(.internalServerError, reason: "Invalid SCHOLARSHIP_API_BASE_URL")
    }

    let from = Environment.get("RESEND_FROM_EMAIL") ?? "Scholarship <scholarship@mail.tryswift.jp>"
    let mail = ScholarshipEmailTemplates.render(
      .magicLink(verifyURL: verifyURL, ttlMinutes: 30),
      locale: locale,
      recipientName: user.displayName
    )
    _ = await ResendClient.send(
      to: user.email, from: from,
      subject: mail.subject, html: mail.htmlBody, text: mail.textBody,
      client: req.client, logger: req.logger
    )

    let nextURL =
      payload.redirect_to.flatMap(URL.init(string:))
      ?? URL(string: "\(studentBase)/login/sent")!
    return req.redirect(to: nextURL.absoluteString)
  }

  func verifyMagicLink(_ req: Request) async throws -> Response {
    let token = req.query[String.self, at: "token"] ?? ""
    let redirectTo = req.query[String.self, at: "redirect_to"]
    let studentBase = studentBaseURL()

    guard !token.isEmpty,
      let user = try await ScholarshipMagicLinkService.verify(rawToken: token, on: req.db)
    else {
      let failURL = "\(studentBase)/login?error=invalid"
      return req.redirect(to: failURL)
    }
    let payload = StudentJWTPayload(userID: try user.requireID(), locale: user.locale)
    let signed = try await req.jwt.sign(payload)
    let target = redirectTo ?? "\(studentBase)/apply"
    let response = req.redirect(to: target)
    response.cookies[StudentAuthCookie.name] = StudentAuthCookie.make(value: signed)
    return response
  }

  func logout(_ req: Request) async throws -> Response {
    let response = Response(status: .noContent)
    response.cookies[StudentAuthCookie.name] = HTTPCookies.Value(
      string: "",
      expires: Date(timeIntervalSince1970: 0),
      maxAge: 0,
      domain: StudentAuthCookie.cookieDomain(),
      path: "/",
      isSecure: Environment.get("APP_ENV") == "production",
      isHTTPOnly: true,
      sameSite: .lax
    )
    return response
  }

  func travelCost(_ req: Request) async throws -> Response {
    guard let from = req.query[String.self, at: "from"], !from.isEmpty else {
      throw Abort(.badRequest, reason: "Missing 'from' query parameter")
    }
    guard let estimate = TravelCostCalculator.estimate(from: from) else {
      throw Abort(.notFound, reason: "City not found")
    }
    let response = Response(status: .ok)
    try response.content.encode(estimate)
    return response
  }

  // MARK: - Applicant endpoints

  func submit(_ req: Request) async throws -> Response {
    guard let user = req.studentUser else { throw Abort(.unauthorized) }
    let payload = try req.content.decode(ScholarshipFormPayload.self)
    guard let conference = try await currentConference(on: req.db) else {
      throw Abort(.serviceUnavailable, reason: "No conference is accepting applications")
    }
    let conferenceID = try conference.requireID()
    let applicantID = try user.requireID()

    if (try await ScholarshipApplication.query(on: req.db)
      .filter(\.$conference.$id == conferenceID)
      .filter(\.$applicant.$id == applicantID)
      .first()) != nil
    {
      throw Abort(.conflict, reason: "You have already submitted an application")
    }

    let travelDetails: ScholarshipTravelDetails?
    let accommodationDetails: ScholarshipAccommodationDetails?
    if payload.supportType == .ticketAndTravel {
      if let originCity = payload.originCity, !originCity.isEmpty,
        let methods = payload.transportationMethods,
        let trip = payload.estimatedRoundTripCost
      {
        travelDetails = ScholarshipTravelDetails(
          originCity: originCity,
          transportationMethods: methods,
          estimatedRoundTripCost: trip)
      } else {
        travelDetails = nil
      }
      if let type = payload.accommodationType,
        let status = payload.reservationStatus,
        let cost = payload.estimatedAccommodationCost
      {
        accommodationDetails = ScholarshipAccommodationDetails(
          accommodationType: type,
          reservationStatus: status,
          accommodationName: payload.accommodationName,
          accommodationAddress: payload.accommodationAddress,
          checkInDate: payload.checkInDate,
          checkOutDate: payload.checkOutDate,
          estimatedCost: cost)
      } else {
        accommodationDetails = nil
      }
    } else {
      travelDetails = nil
      accommodationDetails = nil
    }

    let application = ScholarshipApplication(
      conferenceID: conferenceID,
      applicantID: applicantID,
      email: payload.email,
      name: payload.name,
      schoolAndFaculty: payload.schoolAndFaculty,
      currentYear: payload.currentYear,
      portfolio: payload.portfolio,
      githubAccount: payload.githubAccount,
      purposes: ScholarshipPurposeList(payload.purposes),
      languagePreference: payload.languagePreference,
      existingTicketInfo: payload.existingTicketInfo,
      supportType: payload.supportType,
      travelDetails: travelDetails,
      accommodationDetails: accommodationDetails,
      totalEstimatedCost: payload.totalEstimatedCost,
      desiredSupportAmount: payload.desiredSupportAmount,
      selfPaymentInfo: payload.selfPaymentInfo,
      agreedTravelRegulations: payload.agreedTravelRegulations,
      agreedApplicationConfirmation: payload.agreedApplicationConfirmation,
      agreedPrivacy: payload.agreedPrivacy,
      agreedCodeOfConduct: payload.agreedCodeOfConduct,
      additionalComments: payload.additionalComments
    )
    try await application.save(on: req.db)

    if user.displayName == nil || user.displayName?.isEmpty == true {
      user.displayName = payload.name
      try await user.save(on: req.db)
    }

    let locale = ScholarshipPortalLocale(rawValue: payload.languagePreference) ?? .default
    let mail = ScholarshipEmailTemplates.render(
      .applicationReceived(conferenceName: conference.displayName),
      locale: locale, recipientName: payload.name
    )
    let from = Environment.get("RESEND_FROM_EMAIL") ?? "Scholarship <scholarship@mail.tryswift.jp>"
    _ = await ResendClient.send(
      to: payload.email, from: from,
      subject: mail.subject, html: mail.htmlBody, text: mail.textBody,
      client: req.client, logger: req.logger
    )
    await ScholarshipSlackNotifier.notifyNewApplication(
      name: payload.name, school: payload.schoolAndFaculty,
      supportType: payload.supportType.displayName,
      client: req.client, logger: req.logger
    )

    return req.redirect(to: "\(studentBaseURL())/my-application")
  }

  func myApplication(_ req: Request) async throws -> Response {
    guard let user = req.studentUser else { throw Abort(.unauthorized) }
    let applicantID = try user.requireID()
    let application = try await ScholarshipApplication.query(on: req.db)
      .filter(\.$applicant.$id == applicantID)
      .with(\.$conference)
      .sort(\.$createdAt, .descending)
      .first()
    guard let application else { throw Abort(.notFound) }
    let dto = try application.toDTO(conference: application.conference)
    let response = Response(status: .ok)
    try response.content.encode(dto)
    return response
  }

  func withdraw(_ req: Request) async throws -> Response {
    guard let user = req.studentUser else { throw Abort(.unauthorized) }
    let applicantID = try user.requireID()
    guard
      let application = try await ScholarshipApplication.query(on: req.db)
        .filter(\.$applicant.$id == applicantID)
        .filter(\.$status == .submitted)
        .first()
    else {
      throw Abort(.conflict, reason: "No active application to withdraw")
    }
    application.status = .withdrawn
    try await application.save(on: req.db)
    return req.redirect(to: "\(studentBaseURL())/my-application")
  }

  // MARK: - Organizer endpoints

  func organizerList(_ req: Request) async throws -> Response {
    struct ListResponse: Content {
      let applications: [ScholarshipApplicationDTO]
      let budget: ScholarshipBudgetSummaryDTO?
    }
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
        .filter(\.$conference.$id == conferenceID).first()
      let approved = applications.filter { $0.status == .approved }
        .reduce(0) { $0 + ($1.approvedAmount ?? 0) }
      summary = ScholarshipBudgetSummaryDTO(
        totalBudget: budget?.totalBudget, approvedTotal: approved)
    }
    let response = Response(status: .ok)
    try response.content.encode(ListResponse(applications: dtos, budget: summary))
    return response
  }

  func organizerDetail(_ req: Request) async throws -> Response {
    guard let id = req.parameters.get("id", as: UUID.self) else { throw Abort(.badRequest) }
    let application = try await ScholarshipApplication.query(on: req.db)
      .filter(\.$id == id)
      .with(\.$conference)
      .first()
    guard let application else { throw Abort(.notFound) }
    let dto = try application.toDTO(conference: application.conference)
    let response = Response(status: .ok)
    try response.content.encode(dto)
    return response
  }

  func organizerApprove(_ req: Request) async throws -> Response {
    guard let id = req.parameters.get("id", as: UUID.self) else { throw Abort(.badRequest) }
    let payload = try req.content.decode(ScholarshipApproveActionPayload.self)
    let application = try await ScholarshipApplication.query(on: req.db)
      .filter(\.$id == id).with(\.$conference).first()
    guard let application else { throw Abort(.notFound) }

    application.status = .approved
    application.approvedAmount = payload.approvedAmount
    application.organizerNotes = payload.organizerNotes
    try await application.save(on: req.db)

    let locale = ScholarshipPortalLocale(rawValue: application.languagePreference) ?? .default
    let mail = ScholarshipEmailTemplates.render(
      .applicationApproved(
        conferenceName: application.conference.displayName,
        approvedAmountYen: payload.approvedAmount),
      locale: locale, recipientName: application.name
    )
    let from = Environment.get("RESEND_FROM_EMAIL") ?? "Scholarship <scholarship@mail.tryswift.jp>"
    _ = await ResendClient.send(
      to: application.email, from: from,
      subject: mail.subject, html: mail.htmlBody, text: mail.textBody,
      client: req.client, logger: req.logger
    )
    await ScholarshipSlackNotifier.notifyDecision(
      name: application.name, school: application.schoolAndFaculty,
      decision: "Approved", approvedAmount: payload.approvedAmount,
      client: req.client, logger: req.logger
    )

    return req.redirect(to: "\(studentBaseURL())/organizer/\(id.uuidString)")
  }

  func organizerReject(_ req: Request) async throws -> Response {
    guard let id = req.parameters.get("id", as: UUID.self) else { throw Abort(.badRequest) }
    let payload = try req.content.decode(ScholarshipRejectActionPayload.self)
    let application = try await ScholarshipApplication.query(on: req.db)
      .filter(\.$id == id).with(\.$conference).first()
    guard let application else { throw Abort(.notFound) }

    application.status = .rejected
    application.organizerNotes = payload.organizerNotes
    try await application.save(on: req.db)

    let locale = ScholarshipPortalLocale(rawValue: application.languagePreference) ?? .default
    let mail = ScholarshipEmailTemplates.render(
      .applicationRejected(
        conferenceName: application.conference.displayName,
        reason: payload.organizerNotes),
      locale: locale, recipientName: application.name
    )
    let from = Environment.get("RESEND_FROM_EMAIL") ?? "Scholarship <scholarship@mail.tryswift.jp>"
    _ = await ResendClient.send(
      to: application.email, from: from,
      subject: mail.subject, html: mail.htmlBody, text: mail.textBody,
      client: req.client, logger: req.logger
    )
    await ScholarshipSlackNotifier.notifyDecision(
      name: application.name, school: application.schoolAndFaculty,
      decision: "Rejected",
      client: req.client, logger: req.logger
    )

    return req.redirect(to: "\(studentBaseURL())/organizer/\(id.uuidString)")
  }

  func organizerRevert(_ req: Request) async throws -> Response {
    guard let id = req.parameters.get("id", as: UUID.self) else { throw Abort(.badRequest) }
    guard let application = try await ScholarshipApplication.find(id, on: req.db)
    else { throw Abort(.notFound) }
    application.status = .submitted
    application.approvedAmount = nil
    try await application.save(on: req.db)
    return req.redirect(to: "\(studentBaseURL())/organizer/\(id.uuidString)")
  }

  func organizerBudget(_ req: Request) async throws -> Response {
    struct BudgetResponse: Content {
      let budget: ScholarshipBudgetDTO?
      let summary: ScholarshipBudgetSummaryDTO?
    }
    let conference = try await currentConference(on: req.db)
    var budgetDTO: ScholarshipBudgetDTO?
    var summary: ScholarshipBudgetSummaryDTO?
    if let conference {
      let conferenceID = try conference.requireID()
      let budget = try await ScholarshipBudget.query(on: req.db)
        .filter(\.$conference.$id == conferenceID).first()
      budgetDTO = try budget?.toDTO()
      let applications = try await ScholarshipApplication.query(on: req.db)
        .filter(\.$conference.$id == conferenceID).all()
      let approved = applications.filter { $0.status == .approved }
        .reduce(0) { $0 + ($1.approvedAmount ?? 0) }
      summary = ScholarshipBudgetSummaryDTO(
        totalBudget: budget?.totalBudget, approvedTotal: approved)
    }
    let response = Response(status: .ok)
    try response.content.encode(BudgetResponse(budget: budgetDTO, summary: summary))
    return response
  }

  func organizerSaveBudget(_ req: Request) async throws -> Response {
    let payload = try req.content.decode(ScholarshipBudgetUpdatePayload.self)
    guard let conference = try await currentConference(on: req.db) else {
      throw Abort(.serviceUnavailable, reason: "No conference accepting applications")
    }
    let conferenceID = try conference.requireID()
    if let existing = try await ScholarshipBudget.query(on: req.db)
      .filter(\.$conference.$id == conferenceID).first()
    {
      existing.totalBudget = payload.totalBudget
      existing.notes = payload.notes
      try await existing.save(on: req.db)
    } else {
      let budget = ScholarshipBudget(
        conferenceID: conferenceID,
        totalBudget: payload.totalBudget,
        notes: payload.notes)
      try await budget.save(on: req.db)
    }
    return req.redirect(to: "\(studentBaseURL())/organizer/budget")
  }

  func organizerCSV(_ req: Request) async throws -> Response {
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
        app.status.rawValue, app.name, app.email,
        app.schoolAndFaculty, app.currentYear,
        app.supportType.rawValue,
        app.approvedAmount.map { String($0) } ?? "",
        app.desiredSupportAmount.map { String($0) } ?? "",
        app.totalEstimatedCost.map { String($0) } ?? "",
        app.languagePreference,
        app.purposes.items.joined(separator: "|"),
      ])
    }
    let csv = rows.map { row in row.map(escapeCSV).joined(separator: ",") }
      .joined(separator: "\r\n")

    var headers = HTTPHeaders()
    headers.add(name: .contentType, value: "text/csv; charset=utf-8")
    headers.add(
      name: .contentDisposition,
      value: "attachment; filename=\"scholarship-applications.csv\""
    )
    return Response(status: .ok, headers: headers, body: .init(string: csv))
  }

  // MARK: - Helpers

  private func currentConference(on db: Database) async throws -> Conference? {
    try await Conference.query(on: db).sort(\.$year, .descending).first()
  }

  private func approvedTotal(conferenceID: UUID, on db: Database) async throws -> Int {
    let approved = try await ScholarshipApplication.query(on: db)
      .filter(\.$conference.$id == conferenceID)
      .filter(\.$status == .approved)
      .all()
    return approved.reduce(0) { $0 + ($1.approvedAmount ?? 0) }
  }

  private func findOrCreateUser(
    email: String, on db: Database, locale: ScholarshipPortalLocale
  ) async throws -> StudentUser {
    let normalized = email.lowercased()
    if let existing = try await StudentUser.query(on: db)
      .filter(\.$email == normalized).first()
    {
      return existing
    }
    let user = StudentUser(email: normalized, locale: locale)
    try await user.save(on: db)
    return user
  }

  private func studentBaseURL() -> String {
    Environment.get("STUDENT_BASE_URL") ?? "https://student.tryswift.jp"
  }

  private func apiBaseURL() -> String {
    Environment.get("SCHOLARSHIP_API_BASE_URL")
      ?? Environment.get("API_BASE_URL")
      ?? "https://api.tryswift.jp"
  }

  private func isOrganizerSession(_ req: Request) async -> Bool {
    guard let raw = req.cookies["auth_token"]?.string,
      let payload = try? await req.jwt.verify(raw, as: UserJWTPayload.self)
    else { return false }
    return payload.role == .admin
  }

  private func escapeCSV(_ value: String) -> String {
    var v = value
    if let first = v.first, "=+-@".contains(first) { v = "'" + v }
    let needsQuotes =
      v.contains(",") || v.contains("\"") || v.contains("\n") || v.contains("\r")
    if needsQuotes {
      let escaped = v.replacingOccurrences(of: "\"", with: "\"\"")
      return "\"\(escaped)\""
    }
    return v
  }
}

/// Returns 401 when the request lacks a valid `auth_token` admin session.
/// Used in place of `OrganizerOnlyMiddleware` for /api/v1/* endpoints so the
/// browser-side fetch can react instead of being redirected to cfp.tryswift.jp.
struct ScholarshipOrganizerAuthMiddleware: AsyncMiddleware {
  func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
    guard let raw = request.cookies["auth_token"]?.string,
      let payload = try? await request.jwt.verify(raw, as: UserJWTPayload.self)
    else {
      throw Abort(.unauthorized)
    }
    guard payload.role == .admin else { throw Abort(.forbidden) }
    return try await next.respond(to: request)
  }
}
