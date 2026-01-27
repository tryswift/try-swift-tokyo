import Fluent
import JWT
import SharedModels
import Vapor
import VaporElementary

/// Routes for CfP SSR pages
struct CfPRoutes: RouteCollection {
  func boot(routes: RoutesBuilder) throws {
    let cfp = routes.grouped("cfp")

    // Public pages
    cfp.get(use: homePage)
    cfp.get("guidelines", use: guidelinesPage)
    cfp.get("login", use: loginPage)
    cfp.get("login-page", use: loginPage)  // Backward compatibility

    // Auth-aware pages (check auth but don't require it)
    cfp.get("submit", use: submitPage)
    cfp.get("submit-page", use: submitPage)  // Backward compatibility
    cfp.get("my-proposals", use: myProposalsPage)
    cfp.get("my-proposals-page", use: myProposalsPage)  // Backward compatibility

    // Form submission (POST)
    cfp.post("submit", use: handleSubmitProposal)

    // Logout
    cfp.get("logout", use: logout)

    // Organizer pages (admin only)
    let organizer = cfp.grouped("organizer")
    organizer.get("proposals", use: organizerProposalsPage)
    organizer.get("proposals", "export", use: exportProposalsCSV)
    organizer.get("proposals", ":proposalID", use: organizerProposalDetailPage)
  }

  // MARK: - Page Handlers

  @Sendable
  func homePage(req: Request) async throws -> HTMLResponse {
    let user = try? await getAuthenticatedUser(req: req)
    return HTMLResponse {
      CfPLayout(title: "Call for Proposals", user: user) {
        CfPHomePage(user: user)
      }
    }
  }

  @Sendable
  func guidelinesPage(req: Request) async throws -> HTMLResponse {
    let user = try? await getAuthenticatedUser(req: req)
    return HTMLResponse {
      CfPLayout(title: "Submission Guidelines", user: user) {
        GuidelinesPageView(user: user)
      }
    }
  }

  @Sendable
  func loginPage(req: Request) async throws -> HTMLResponse {
    let user = try? await getAuthenticatedUser(req: req)
    let error = req.query[String.self, at: "error"]
    return HTMLResponse {
      CfPLayout(title: "Login", user: user) {
        LoginPageView(user: user, error: error)
      }
    }
  }

  @Sendable
  func submitPage(req: Request) async throws -> HTMLResponse {
    let user = try? await getAuthenticatedUser(req: req)
    let success = req.query[String.self, at: "success"] == "true"

    // Check if there's an open conference
    let openConference = try await Conference.query(on: req.db)
      .filter(\.$isOpen == true)
      .sort(\.$year, .descending)
      .first()

    return HTMLResponse {
      CfPLayout(title: "Submit Proposal", user: user) {
        SubmitPageView(
          user: user, success: success, errorMessage: nil,
          openConference: openConference?.toPublicInfo())
      }
    }
  }

  @Sendable
  func myProposalsPage(req: Request) async throws -> HTMLResponse {
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

    return HTMLResponse {
      CfPLayout(title: "My Proposals", user: user) {
        MyProposalsPageView(user: user, proposals: proposals)
      }
    }
  }

  // MARK: - Form Handlers

  @Sendable
  func handleSubmitProposal(req: Request) async throws -> Response {
    guard let user = try? await getAuthenticatedUser(req: req) else {
      return req.redirect(to: "/api/v1/auth/github?returnTo=/cfp/submit")
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
        req: req, user: user, error: "Invalid form data")
    }

    // Validate
    guard !formData.title.isEmpty else {
      return try await renderSubmitPageWithError(req: req, user: user, error: "Title is required")
    }
    guard !formData.abstract.isEmpty else {
      return try await renderSubmitPageWithError(
        req: req, user: user, error: "Abstract is required")
    }
    guard !formData.talkDetails.isEmpty else {
      return try await renderSubmitPageWithError(
        req: req, user: user, error: "Talk details are required")
    }
    guard !formData.bio.isEmpty else {
      return try await renderSubmitPageWithError(
        req: req, user: user, error: "Speaker bio is required")
    }

    guard let talkDuration = TalkDuration(rawValue: formData.talkDuration) else {
      return try await renderSubmitPageWithError(
        req: req, user: user, error: "Please select a talk duration")
    }

    // Find current open conference
    guard
      let conference = try await Conference.query(on: req.db)
        .filter(\.$isOpen == true)
        .sort(\.$year, .descending)
        .first()
    else {
      return try await renderSubmitPageWithError(
        req: req, user: user,
        error:
          "The Call for Proposals is not currently open. Please check back later for the next conference."
      )
    }

    guard let conferenceID = conference.id else {
      return try await renderSubmitPageWithError(
        req: req, user: user, error: "Conference configuration error")
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
    return req.redirect(to: "/cfp/submit?success=true")
  }

  private func renderSubmitPageWithError(req: Request, user: UserDTO, error: String) async throws
    -> Response
  {
    let html = HTMLResponse {
      CfPLayout(title: "Submit Proposal", user: user) {
        SubmitPageView(user: user, success: false, errorMessage: error)
      }
    }
    return try await html.encodeResponse(for: req)
  }

  // MARK: - Logout

  @Sendable
  func logout(req: Request) async throws -> Response {
    let response = req.redirect(to: "/cfp/")

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
        CfPLayout(title: "All Proposals", user: user) {
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
      CfPLayout(title: "All Proposals", user: user) {
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
        CfPLayout(title: "Proposal Detail", user: user) {
          OrganizerProposalDetailPageView(user: user, proposal: nil)
        }
      }
    }

    guard let proposalID = req.parameters.get("proposalID", as: UUID.self) else {
      return HTMLResponse {
        CfPLayout(title: "Proposal Detail", user: user) {
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
      CfPLayout(title: proposal?.title ?? "Proposal Detail", user: user) {
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
    var csv = "ID,Title,Speaker Username,Talk Duration,Conference,Abstract,Talk Detail,Bio,Icon URL,Notes,Created At\n"

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

      csv += "\(id),\(title),\(speakerUsername),\(talkDuration),\(conference),\(abstract),\(talkDetail),\(bio),\(iconURL),\(notes),\(createdAt)\n"
    }

    let response = Response(status: .ok)
    response.headers.contentType = HTTPMediaType(type: "text", subType: "csv", parameters: ["charset": "utf-8"])
    let filename = conferencePath.map { "proposals-\($0).csv" } ?? "proposals-all.csv"
    response.headers.add(name: "Content-Disposition", value: "attachment; filename=\"\(filename)\"")
    response.body = .init(string: csv)

    return response
  }

  private func escapeCSV(_ value: String) -> String {
    let needsQuotes = value.contains(",") || value.contains("\"") || value.contains("\n") || value.contains("\r")
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
