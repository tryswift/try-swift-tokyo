import Elementary
import Fluent
import JWT
import SharedModels
import Vapor
import WebSponsor

struct SponsorPublicController: RouteCollection {
  func boot(routes: RoutesBuilder) throws {
    routes.get(use: landing)
    routes.get("inquiry", use: renderInquiry)
    routes.post("inquiry", use: submitInquiry)
    routes.get("inquiry", "thanks", use: inquiryThanks)
    routes.get("login", use: renderLogin)
    routes.post("login", use: requestMagicLink)
    routes.get("login", "sent", use: loginSent)
    routes.get("auth", "verify", use: verifyMagicLink)
    routes.post("logout", use: logout)
  }

  func landing(_ req: Request) async throws -> Response {
    try await renderInquiry(req)
  }

  func renderInquiry(_ req: Request) async throws -> Response {
    respond(InquiryFormPage(locale: req.sponsorLocale, csrfToken: ""))
  }

  func submitInquiry(_ req: Request) async throws -> Response {
    let payload = try req.content.decode(SponsorInquiryFormPayload.self)
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
      desiredPlanSlug: payload.desiredPlanSlug,
      message: payload.message ?? "",
      locale: req.sponsorLocale
    )
    try await inquiry.save(on: req.db)

    let user: SponsorUser
    if let existing = try await SponsorUser.query(on: req.db)
      .filter(\.$email == payload.email.lowercased()).first()
    {
      user = existing
    } else {
      user = SponsorUser(
        email: payload.email, displayName: payload.contactName, locale: req.sponsorLocale)
      try await user.save(on: req.db)
    }

    let issued = try await MagicLinkService.issue(for: user, on: req.db)
    let baseURL = Environment.get("SPONSOR_BASE_URL") ?? "https://sponsor.tryswift.jp"
    let verifyURL = URL(string: "\(baseURL)/auth/verify?token=\(issued.rawToken)")!
    let materialsURL = URL(
      string: Environment.get("SPONSOR_MATERIALS_URL")
        ?? "\(baseURL)/sponsor/materials/sponsor-pack-2026.pdf")!
    let from = Environment.get("RESEND_FROM_EMAIL") ?? "Sponsorship <sponsorship@mail.tryswift.jp>"

    let mat = SponsorEmailTemplates.render(
      .inquiryReceived(materialsURL: materialsURL),
      locale: req.sponsorLocale,
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
      locale: req.sponsorLocale,
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
      planSlug: payload.desiredPlanSlug,
      client: req.client,
      logger: req.logger)

    return req.redirect(to: "/inquiry/thanks")
  }

  func inquiryThanks(_ req: Request) async throws -> Response {
    respond(InquiryThanksPage(locale: req.sponsorLocale))
  }

  func renderLogin(_ req: Request) async throws -> Response {
    respond(LoginRequestPage(locale: req.sponsorLocale, csrfToken: ""))
  }

  func requestMagicLink(_ req: Request) async throws -> Response {
    let payload = try req.content.decode(MagicLinkRequestPayload.self)
    if let user = try await SponsorUser.query(on: req.db)
      .filter(\.$email == payload.email.lowercased()).first()
    {
      let issued = try await MagicLinkService.issue(for: user, on: req.db)
      let baseURL = Environment.get("SPONSOR_BASE_URL") ?? "https://sponsor.tryswift.jp"
      let url = URL(string: "\(baseURL)/auth/verify?token=\(issued.rawToken)")!
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
    return req.redirect(to: "/login/sent")
  }

  func loginSent(_ req: Request) async throws -> Response {
    respond(LoginSentPage(locale: req.sponsorLocale))
  }

  func verifyMagicLink(_ req: Request) async throws -> Response {
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

    let response = req.redirect(to: "/dashboard")
    response.cookies[SponsorAuthCookie.name] = SponsorAuthCookie.make(value: signed)
    return response
  }

  func logout(_ req: Request) async throws -> Response {
    let response = req.redirect(to: "/login")
    response.cookies[SponsorAuthCookie.name] = HTTPCookies.Value(
      string: "",
      expires: Date(timeIntervalSince1970: 0),
      maxAge: 0,
      domain: SponsorAuthCookie.cookieDomain(),
      path: "/",
      isHTTPOnly: true,
      sameSite: .lax)
    return response
  }

  private func respond<Page: HTML>(_ page: Page) -> Response {
    let html = page.render()
    var headers = HTTPHeaders()
    headers.contentType = .html
    return Response(status: .ok, headers: headers, body: .init(string: html))
  }
}
