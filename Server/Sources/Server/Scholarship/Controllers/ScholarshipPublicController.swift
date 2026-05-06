import Elementary
import Fluent
import Foundation
import JWT
import SharedModels
import Vapor
import WebScholarship

/// Public, unauthenticated routes for student.tryswift.jp:
/// - landing page (info + budget summary)
/// - magic-link login request and verification
/// - logout
struct ScholarshipPublicController: RouteCollection {
  func boot(routes: RoutesBuilder) throws {
    routes.get(use: landing)
    routes.get("login", use: renderLogin)
    routes.post("login", use: requestMagicLink)
    routes.get("login", "sent", use: loginSent)
    routes.get("auth", "verify", use: verifyMagicLink)
    routes.post("logout", use: logout)
  }

  // MARK: Landing

  func landing(_ req: Request) async throws -> Response {
    let conference = try await currentConference(on: req.db)
    let budgetSummary: ScholarshipBudgetSummaryDTO?
    if let conf = conference {
      let budget = try? await ScholarshipBudget.query(on: req.db)
        .filter(\.$conference.$id == (try conf.requireID()))
        .first()
      let approvedSum = try await approvedTotal(conferenceID: try conf.requireID(), on: req.db)
      budgetSummary = ScholarshipBudgetSummaryDTO(
        totalBudget: budget?.totalBudget,
        approvedTotal: approvedSum
      )
    } else {
      budgetSummary = nil
    }

    let isAuthenticated =
      (try? await req.jwt.verify(
        req.cookies[StudentAuthCookie.name]?.string ?? "", as: StudentJWTPayload.self)) != nil

    return respond(
      InfoPage(
        locale: req.studentLocale,
        isAuthenticated: isAuthenticated,
        conferenceName: conference?.displayName,
        budget: budgetSummary
      )
    )
  }

  // MARK: Login

  func renderLogin(_ req: Request) async throws -> Response {
    let error = req.query[String.self, at: "error"]
    let errorMessage = error.map { _ in ScholarshipStrings.t(.loginInvalid, req.studentLocale) }
    return respond(
      LoginRequestPage(
        locale: req.studentLocale, csrfToken: req.csrfToken, errorMessage: errorMessage)
    )
  }

  func requestMagicLink(_ req: Request) async throws -> Response {
    let payload = try req.content.decode(ScholarshipLoginRequestPayload.self)
    let trimmed = payload.email.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { throw Abort(.badRequest, reason: "Email required") }

    let user = try await findOrCreateUser(email: trimmed, on: req.db, locale: req.studentLocale)
    let issued = try await ScholarshipMagicLinkService.issue(for: user, on: req.db)

    let baseURL = Environment.get("STUDENT_BASE_URL") ?? "https://student.tryswift.jp"
    guard let verifyURL = URL(string: "\(baseURL)/auth/verify?token=\(issued.rawToken)") else {
      throw Abort(.internalServerError, reason: "Invalid STUDENT_BASE_URL")
    }
    let from = Environment.get("RESEND_FROM_EMAIL") ?? "Scholarship <scholarship@mail.tryswift.jp>"
    let mail = ScholarshipEmailTemplates.render(
      .magicLink(verifyURL: verifyURL, ttlMinutes: 30),
      locale: req.studentLocale,
      recipientName: user.displayName
    )
    _ = await ResendClient.send(
      to: user.email, from: from,
      subject: mail.subject, html: mail.htmlBody, text: mail.textBody,
      client: req.client, logger: req.logger
    )

    return req.redirect(to: "/login/sent")
  }

  func loginSent(_ req: Request) async throws -> Response {
    respond(LoginSentPage(locale: req.studentLocale))
  }

  func verifyMagicLink(_ req: Request) async throws -> Response {
    guard let token = req.query[String.self, at: "token"], !token.isEmpty else {
      return req.redirect(to: "/login?error=missing")
    }
    guard let user = try await ScholarshipMagicLinkService.verify(rawToken: token, on: req.db)
    else {
      return req.redirect(to: "/login?error=invalid")
    }

    let payload = StudentJWTPayload(
      userID: try user.requireID(),
      locale: req.studentLocale
    )
    let signed = try await req.jwt.sign(payload)
    let response = req.redirect(to: "/apply")
    response.cookies[StudentAuthCookie.name] = StudentAuthCookie.make(value: signed)
    return response
  }

  // MARK: Logout

  func logout(_ req: Request) async throws -> Response {
    let response = req.redirect(to: "/")
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

  // MARK: Helpers

  private func findOrCreateUser(
    email: String,
    on db: Database,
    locale: ScholarshipPortalLocale
  ) async throws -> StudentUser {
    let normalized = email.lowercased()
    if let existing = try await StudentUser.query(on: db)
      .filter(\.$email == normalized)
      .first()
    {
      return existing
    }
    let user = StudentUser(email: normalized, locale: locale)
    try await user.save(on: db)
    return user
  }

  private func currentConference(on db: Database) async throws -> Conference? {
    try await Conference.query(on: db)
      .sort(\.$year, .descending)
      .first()
  }

  private func approvedTotal(conferenceID: UUID, on db: Database) async throws -> Int {
    let approved = try await ScholarshipApplication.query(on: db)
      .filter(\.$conference.$id == conferenceID)
      .filter(\.$status == .approved)
      .all()
    return approved.reduce(0) { $0 + ($1.approvedAmount ?? 0) }
  }

  private func respond<Page: HTML>(_ page: Page) -> Response {
    let html = page.render()
    var headers = HTTPHeaders()
    headers.contentType = .html
    return Response(status: .ok, headers: headers, body: .init(string: html))
  }
}
