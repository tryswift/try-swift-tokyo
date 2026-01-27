import Fluent
import JWT
import SharedModels
import Vapor
import VaporElementary

/// Routes for CfP SSR pages
struct CfPRoutes: RouteCollection {
  func boot(routes: RoutesBuilder) throws {
    let cfp = routes.grouped("cfp")

    // Redirect root /cfp to /cfp/en/
    cfp.get { req -> Response in
      // Check Accept-Language header for preferred language
      let acceptLanguage = req.headers.first(name: .acceptLanguage) ?? ""
      let preferredLanguage: CfPLanguage = acceptLanguage.lowercased().contains("ja") ? .ja : .en
      return req.redirect(to: "/cfp/\(preferredLanguage.urlPrefix)/")
    }

    // Language-specific routes
    for lang in CfPLanguage.allCases {
      let langGroup = cfp.grouped(PathComponent(stringLiteral: lang.rawValue))

      // Public pages
      langGroup.get(use: { req in try await homePage(req: req, language: lang) })
      langGroup.get("guidelines", use: { req in try await guidelinesPage(req: req, language: lang) })
      langGroup.get("login", use: { req in try await loginPage(req: req, language: lang) })
      langGroup.get(
        "login-page", use: { req in try await loginPage(req: req, language: lang) })  // Backward compatibility

      // Auth-aware pages (check auth but don't require it)
      langGroup.get("submit", use: { req in try await submitPage(req: req, language: lang) })
      langGroup.get(
        "submit-page", use: { req in try await submitPage(req: req, language: lang) })  // Backward compatibility
      langGroup.get(
        "my-proposals", use: { req in try await myProposalsPage(req: req, language: lang) })
      langGroup.get(
        "my-proposals-page",
        use: { req in try await myProposalsPage(req: req, language: lang) })  // Backward compatibility

      // Form submission (POST)
      langGroup.post("submit", use: { req in try await handleSubmitProposal(req: req, language: lang) })

      // Logout
      langGroup.get("logout", use: { req in try await logout(req: req, language: lang) })
    }

    // Legacy routes without language prefix - redirect to English
    cfp.get("guidelines") { req -> Response in
      return req.redirect(to: "/cfp/en/guidelines")
    }
    cfp.get("login") { req -> Response in
      return req.redirect(to: "/cfp/en/login")
    }
    cfp.get("submit") { req -> Response in
      return req.redirect(to: "/cfp/en/submit")
    }
    cfp.get("my-proposals") { req -> Response in
      return req.redirect(to: "/cfp/en/my-proposals")
    }
    cfp.get("logout") { req -> Response in
      return req.redirect(to: "/cfp/en/logout")
    }

    // Organizer pages (admin only) - not localized
    let organizer = cfp.grouped("organizer")
    organizer.get("proposals", use: organizerProposalsPage)
    organizer.get("proposals", "export", use: exportProposalsCSV)
    organizer.get("proposals", ":proposalID", use: organizerProposalDetailPage)
  }

  // MARK: - Page Handlers

  @Sendable
  func homePage(req: Request, language: CfPLanguage) async throws -> HTMLResponse {
    let user = try? await getAuthenticatedUser(req: req)
    let title =
      language == .ja
        ? "スピーカー募集" : "Call for Proposals"
    return HTMLResponse {
      CfPLayout(title: title, user: user, language: language) {
        CfPHomePage(user: user, language: language)
      }
    }
  }

  @Sendable
  func guidelinesPage(req: Request, language: CfPLanguage) async throws -> HTMLResponse {
    let user = try? await getAuthenticatedUser(req: req)
    let title = CfPStrings.Guidelines.title(language)
    return HTMLResponse {
      CfPLayout(title: title, user: user, language: language) {
        GuidelinesPageView(user: user, language: language)
      }
    }
  }

  @Sendable
  func loginPage(req: Request, language: CfPLanguage) async throws -> HTMLResponse {
    let user = try? await getAuthenticatedUser(req: req)
    let error = req.query[String.self, at: "error"]
    let title = CfPStrings.Login.title(language)
    return HTMLResponse {
      CfPLayout(title: title, user: user, language: language) {
        LoginPageView(user: user, error: error, language: language)
      }
    }
  }

  @Sendable
  func submitPage(req: Request, language: CfPLanguage) async throws -> HTMLResponse {
    let user = try? await getAuthenticatedUser(req: req)
    let success = req.query[String.self, at: "success"] == "true"

    // Check if there's an open conference
    let openConference = try await Conference.query(on: req.db)
      .filter(\.$isOpen == true)
      .sort(\.$year, .descending)
      .first()

    let title = CfPStrings.Submit.title(language)
    return HTMLResponse {
      CfPLayout(title: title, user: user, language: language) {
        SubmitPageView(
          user: user,
          success: success,
          errorMessage: nil,
          openConference: openConference?.toPublicInfo(),
          language: language
        )
      }
    }
  }

  @Sendable
  func myProposalsPage(req: Request, language: CfPLanguage) async throws -> HTMLResponse {
    let user = try? await getAuthenticatedUser(req: req)
    var proposals: [ProposalDTO] = []

    if let user {
      let dbProposals = try await Proposal.query(on: req.db)
        .filter(\.$speaker.$id == user.id)
        .with(\.$conference)
        .sort(\.$createdAt, .descending)
        .all()
      proposals = try dbProposals.map {
        try $0.toDTO(speakerUsername: user.username, conference: $0.conference)
      }
    }

    let title = CfPStrings.MyProposals.title(language)
    return HTMLResponse {
      CfPLayout(title: title, user: user, language: language) {
        MyProposalsPageView(user: user, proposals: proposals, language: language)
      }
    }
  }

  // MARK: - Form Handlers

  @Sendable
  func handleSubmitProposal(req: Request, language: CfPLanguage) async throws -> Response {
    guard let user = try? await getAuthenticatedUser(req: req) else {
      return req.redirect(to: "/api/v1/auth/github?returnTo=/cfp/\(language.urlPrefix)/submit")
    }

    // Decode form data
    struct ProposalFormData: Content {
      var title: String
      var abstract: String
      var talkDetails: String
      var talkDuration: String
      var bio: String
      var iconUrl: String?
      var notesToOrganizers: String?
    }

    let formData: ProposalFormData
    do {
      formData = try req.content.decode(ProposalFormData.self)
    } catch {
      return try await renderSubmitPageWithError(
        req: req, user: user, error: "Invalid form data", language: language)
    }

    // Validate
    guard !formData.title.isEmpty else {
      return try await renderSubmitPageWithError(
        req: req, user: user, error: "Title is required", language: language)
    }
    guard !formData.abstract.isEmpty else {
      return try await renderSubmitPageWithError(
        req: req, user: user, error: "Abstract is required", language: language)
    }
    guard !formData.talkDetails.isEmpty else {
      return try await renderSubmitPageWithError(
        req: req, user: user, error: "Talk details are required", language: language)
    }
    guard !formData.bio.isEmpty else {
      return try await renderSubmitPageWithError(
        req: req, user: user, error: "Speaker bio is required", language: language)
    }

    guard let talkDuration = TalkDuration(rawValue: formData.talkDuration) else {
      return try await renderSubmitPageWithError(
        req: req, user: user, error: "Please select a talk duration", language: language)
    }

    // Find current open conference
    guard
      let conference = try await Conference.query(on: req.db)
        .filter(\.$isOpen == true)
        .sort(\.$year, .descending)
        .first()
    else {
      let errorMessage =
        language == .ja
          ? "現在、スピーカー募集は行っていません。次回のカンファレンスをお待ちください。"
          : "The Call for Proposals is not currently open. Please check back later for the next conference."
      return try await renderSubmitPageWithError(
        req: req, user: user, error: errorMessage, language: language)
    }

    guard let conferenceID = conference.id else {
      return try await renderSubmitPageWithError(
        req: req, user: user, error: "Conference configuration error", language: language)
    }

    // Create proposal
    let proposal = Proposal(
      conferenceID: conferenceID,
      title: formData.title,
      abstract: formData.abstract,
      talkDetail: formData.talkDetails,
      talkDuration: talkDuration,
      bio: formData.bio,
      iconURL: formData.iconUrl?.isEmpty == true ? nil : formData.iconUrl,
      notes: formData.notesToOrganizers?.isEmpty == true ? nil : formData.notesToOrganizers,
      speakerID: user.id
    )

    try await proposal.save(on: req.db)

    // Redirect to success page
    return req.redirect(to: "/cfp/\(language.urlPrefix)/submit?success=true")
  }

  private func renderSubmitPageWithError(
    req: Request, user: UserDTO, error: String, language: CfPLanguage
  ) async throws
    -> Response
  {
    let title = CfPStrings.Submit.title(language)
    let html = HTMLResponse {
      CfPLayout(title: title, user: user, language: language) {
        SubmitPageView(user: user, success: false, errorMessage: error, language: language)
      }
    }
    return try await html.encodeResponse(for: req)
  }

  // MARK: - Logout

  @Sendable
  func logout(req: Request, language: CfPLanguage) async throws -> Response {
    let response = req.redirect(to: "/cfp/\(language.urlPrefix)/")

    // Clear auth cookies
    response.cookies["cfp_token"] = HTTPCookies.Value(
      string: "",
      expires: Date(timeIntervalSince1970: 0),
      maxAge: 0,
      path: "/",
      isHTTPOnly: true
    )
    response.cookies["cfp_username"] = HTTPCookies.Value(
      string: "",
      expires: Date(timeIntervalSince1970: 0),
      maxAge: 0,
      path: "/",
      isHTTPOnly: false
    )

    return response
  }

  // MARK: - Organizer Pages

  @Sendable
  func organizerProposalsPage(req: Request) async throws -> HTMLResponse {
    let user = try? await getAuthenticatedUser(req: req)

    // Check if user is admin
    guard let user, user.role == .admin else {
      return HTMLResponse {
        CfPLayout(title: "All Proposals", user: user, language: .en) {
          OrganizerProposalsPageView(user: user, proposals: [], conferencePath: nil)
        }
      }
    }

    // Get optional conference filter
    let conferencePath = req.query[String.self, at: "conference"]

    // Fetch proposals
    var query = Proposal.query(on: req.db)
      .with(\.$conference)
      .with(\.$speaker)
      .sort(\.$createdAt, .descending)

    if let conferencePath {
      query = query.join(Conference.self, on: \Proposal.$conference.$id == \Conference.$id)
        .filter(Conference.self, \.$path == conferencePath)
    }

    let dbProposals = try await query.all()
    let proposals = try dbProposals.map {
      try $0.toDTO(speakerUsername: $0.speaker.username, conference: $0.conference)
    }

    return HTMLResponse {
      CfPLayout(title: "All Proposals", user: user, language: .en) {
        OrganizerProposalsPageView(user: user, proposals: proposals, conferencePath: conferencePath)
      }
    }
  }

  @Sendable
  func organizerProposalDetailPage(req: Request) async throws -> HTMLResponse {
    let user = try? await getAuthenticatedUser(req: req)

    // Check if user is admin
    guard let user, user.role == .admin else {
      return HTMLResponse {
        CfPLayout(title: "Proposal Detail", user: user, language: .en) {
          OrganizerProposalDetailPageView(user: user, proposal: nil)
        }
      }
    }

    guard let proposalID = req.parameters.get("proposalID", as: UUID.self) else {
      return HTMLResponse {
        CfPLayout(title: "Proposal Detail", user: user, language: .en) {
          OrganizerProposalDetailPageView(user: user, proposal: nil)
        }
      }
    }

    let dbProposal = try await Proposal.query(on: req.db)
      .filter(\.$id == proposalID)
      .with(\.$conference)
      .with(\.$speaker)
      .first()

    let proposal = try dbProposal.map {
      try $0.toDTO(speakerUsername: $0.speaker.username, conference: $0.conference)
    }

    return HTMLResponse {
      CfPLayout(title: proposal?.title ?? "Proposal Detail", user: user, language: .en) {
        OrganizerProposalDetailPageView(user: user, proposal: proposal)
      }
    }
  }

  @Sendable
  func exportProposalsCSV(req: Request) async throws -> Response {
    // Check if user is admin
    guard let user = try? await getAuthenticatedUser(req: req), user.role == .admin else {
      throw Abort(.forbidden, reason: "Organizer access required")
    }

    // Get optional conference filter
    let conferencePath = req.query[String.self, at: "conference"]

    // Fetch proposals
    var query = Proposal.query(on: req.db)
      .with(\.$conference)
      .with(\.$speaker)
      .sort(\.$createdAt, .descending)

    if let conferencePath {
      query = query.join(Conference.self, on: \Proposal.$conference.$id == \Conference.$id)
        .filter(Conference.self, \.$path == conferencePath)
    }

    let dbProposals = try await query.all()

    // Generate CSV
    var csv =
      "ID,Title,Speaker Username,Talk Duration,Conference,Abstract,Talk Detail,Bio,Icon URL,Notes,Created At\n"

    let dateFormatter = ISO8601DateFormatter()

    for proposal in dbProposals {
      let id = proposal.id?.uuidString ?? ""
      let title = escapeCSV(proposal.title)
      let speakerUsername = escapeCSV(proposal.speaker.username)
      let talkDuration = proposal.talkDuration.rawValue
      let conference = escapeCSV(proposal.conference.displayName)
      let abstract = escapeCSV(proposal.abstract)
      let talkDetail = escapeCSV(proposal.talkDetail)
      let bio = escapeCSV(proposal.bio)
      let iconURL = proposal.iconURL ?? ""
      let notes = escapeCSV(proposal.notes ?? "")
      let createdAt = proposal.createdAt.map { dateFormatter.string(from: $0) } ?? ""

      csv +=
        "\(id),\(title),\(speakerUsername),\(talkDuration),\(conference),\(abstract),\(talkDetail),\(bio),\(iconURL),\(notes),\(createdAt)\n"
    }

    let response = Response(status: .ok)
    response.headers.contentType = HTTPMediaType(
      type: "text", subType: "csv", parameters: ["charset": "utf-8"])
    let filename = conferencePath.map { "proposals-\($0).csv" } ?? "proposals-all.csv"
    response.headers.add(name: "Content-Disposition", value: "attachment; filename=\"\(filename)\"")
    response.body = .init(string: csv)

    return response
  }

  private func escapeCSV(_ value: String) -> String {
    let needsQuotes =
      value.contains(",") || value.contains("\"") || value.contains("\n") || value.contains("\r")
    if needsQuotes {
      let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
      return "\"\(escaped)\""
    }
    return value
  }

  // MARK: - Helper Methods

  /// Get authenticated user from cookie or authorization header
  func getAuthenticatedUser(req: Request) async throws -> UserDTO? {
    // Try to get token from cookie first, then Authorization header
    let token: String?
    if let cookieToken = req.cookies["cfp_token"]?.string, !cookieToken.isEmpty {
      token = cookieToken
    } else if let authHeader = req.headers.bearerAuthorization?.token {
      token = authHeader
    } else {
      return nil
    }

    guard let token else { return nil }

    let payload = try await req.jwt.verify(token, as: UserJWTPayload.self)
    guard let userID = payload.userID else { return nil }
    guard let user = try await User.find(userID, on: req.db) else { return nil }

    return try user.toDTO()
  }
}
