import Fluent
import JWT
import SharedModels
import Vapor
import VaporElementary

/// Routes for CfP SSR pages
struct CfPRoutes: RouteCollection {
  func boot(routes: RoutesBuilder) throws {
    // English routes (default) - at root level
    routes.get(use: homePage)
    routes.get("guidelines", use: guidelinesPage)
    routes.get("login", use: loginPage)
    routes.get("login-page", use: loginPage)  // Backward compatibility
    routes.get("submit", use: submitPage)
    routes.get("submit-page", use: submitPage)  // Backward compatibility
    routes.get("my-proposals", use: myProposalsPage)
    routes.get("my-proposals-page", use: myProposalsPage)  // Backward compatibility
    routes.get("my-proposals", ":proposalID", use: myProposalDetailPage)

    // Profile setup page
    routes.get("profile", use: profilePage)
    routes.post("profile", use: handleUpdateProfile)

    routes.post("submit", use: handleSubmitProposal)
    routes.get("logout", use: logout)

    // Japanese routes
    let ja = routes.grouped("ja")
    ja.get(use: homePageJa)
    ja.get("guidelines", use: guidelinesPageJa)
    ja.get("login", use: loginPageJa)
    ja.get("submit", use: submitPageJa)
    ja.get("my-proposals", use: myProposalsPageJa)
    ja.get("my-proposals", ":proposalID", use: myProposalDetailPageJa)
    ja.post("submit", use: handleSubmitProposalJa)
    ja.get("logout", use: logoutJa)

    // Organizer pages
    let organizer = routes.grouped("organizer")
    organizer.get("proposals", use: organizerProposalsPage)
    organizer.get("proposals", "export", use: organizerExportProposalsCSV)
    organizer.get("proposals", ":proposalID", use: organizerProposalDetailPage)

    // Backward compatibility: redirect /cfp/* to /*
    let cfpRedirect = routes.grouped("cfp")
    cfpRedirect.get { req in req.redirect(to: "/", redirectType: .permanent) }
    cfpRedirect.get("**") { req -> Response in
      let path = req.url.path.replacingOccurrences(of: "/cfp", with: "")
      return req.redirect(to: path.isEmpty ? "/" : path, redirectType: .permanent)
    }
  }

  // MARK: - English Page Handlers

  @Sendable
  func homePage(req: Request) async throws -> HTMLResponse {
    try await renderHomePage(req: req, language: .en)
  }

  @Sendable
  func guidelinesPage(req: Request) async throws -> HTMLResponse {
    try await renderGuidelinesPage(req: req, language: .en)
  }

  @Sendable
  func loginPage(req: Request) async throws -> Response {
    let user = try? await getAuthenticatedUser(req: req)
    let error = req.query[String.self, at: "error"]

    // If user is logged in and profile is incomplete, redirect to profile setup
    if let user, isProfileIncomplete(user) {
      return req.redirect(to: "/profile?returnTo=/submit")
    }

    let html = HTMLResponse {
      CfPLayout(
        title: "Login",
        user: user,
        language: .en,
        currentPath: "/login"
      ) {
        LoginPageView(user: user, error: error, language: .en)
      }
    }
    return try await html.encodeResponse(for: req)
  }

  /// Check if user profile is incomplete (missing required fields)
  private func isProfileIncomplete(_ user: UserDTO) -> Bool {
    user.displayName == nil || user.displayName?.isEmpty == true || user.email == nil
      || user.email?.isEmpty == true || user.bio == nil || user.bio?.isEmpty == true
      || user.avatarURL == nil || user.avatarURL?.isEmpty == true
  }

  @Sendable
  func submitPage(req: Request) async throws -> HTMLResponse {
    try await renderSubmitPage(req: req, language: .en)
  }

  @Sendable
  func myProposalsPage(req: Request) async throws -> HTMLResponse {
    try await renderMyProposalsPage(req: req, language: .en)
  }

  @Sendable
  func myProposalDetailPage(req: Request) async throws -> HTMLResponse {
    try await renderMyProposalDetailPage(req: req, language: .en)
  }

  // MARK: - Japanese Page Handlers

  @Sendable
  func homePageJa(req: Request) async throws -> HTMLResponse {
    try await renderHomePage(req: req, language: .ja)
  }

  @Sendable
  func guidelinesPageJa(req: Request) async throws -> HTMLResponse {
    try await renderGuidelinesPage(req: req, language: .ja)
  }

  @Sendable
  func loginPageJa(req: Request) async throws -> HTMLResponse {
    try await renderLoginPage(req: req, language: .ja)
  }

  @Sendable
  func submitPageJa(req: Request) async throws -> HTMLResponse {
    try await renderSubmitPage(req: req, language: .ja)
  }

  @Sendable
  func myProposalsPageJa(req: Request) async throws -> HTMLResponse {
    try await renderMyProposalsPage(req: req, language: .ja)
  }

  @Sendable
  func myProposalDetailPageJa(req: Request) async throws -> HTMLResponse {
    try await renderMyProposalDetailPage(req: req, language: .ja)
  }

  // MARK: - Shared Render Methods

  private func renderHomePage(req: Request, language: CfPLanguage) async throws -> HTMLResponse {
    let user = try? await getAuthenticatedUser(req: req)
    return HTMLResponse {
      CfPLayout(
        title: language == .ja ? "プロポーザル募集" : "Call for Proposals",
        user: user,
        language: language,
        currentPath: "/"
      ) {
        CfPHomePage(user: user, language: language)
      }
    }
  }

  private func renderGuidelinesPage(req: Request, language: CfPLanguage) async throws
    -> HTMLResponse
  {
    let user = try? await getAuthenticatedUser(req: req)
    return HTMLResponse {
      CfPLayout(
        title: language == .ja ? "応募ガイドライン" : "Submission Guidelines",
        user: user,
        language: language,
        currentPath: "/guidelines"
      ) {
        GuidelinesPageView(user: user, language: language)
      }
    }
  }

  private func renderLoginPage(req: Request, language: CfPLanguage) async throws -> HTMLResponse {
    let user = try? await getAuthenticatedUser(req: req)
    let error = req.query[String.self, at: "error"]
    return HTMLResponse {
      CfPLayout(
        title: language == .ja ? "ログイン" : "Login",
        user: user,
        language: language,
        currentPath: "/login"
      ) {
        LoginPageView(user: user, error: error, language: language)
      }
    }
  }

  private func renderSubmitPage(req: Request, language: CfPLanguage) async throws -> HTMLResponse {
    let user = try? await getAuthenticatedUser(req: req)
    let success = req.query[String.self, at: "success"] == "true"

    // Check if there's an open conference
    let openConference = try await Conference.query(on: req.db)
      .filter(\.$isOpen == true)
      .sort(\.$year, .descending)
      .first()

    return HTMLResponse {
      CfPLayout(
        title: language == .ja ? "プロポーザルを提出" : "Submit Proposal",
        user: user,
        language: language,
        currentPath: "/submit"
      ) {
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

  private func renderMyProposalsPage(req: Request, language: CfPLanguage) async throws
    -> HTMLResponse
  {
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
      CfPLayout(
        title: language == .ja ? "マイプロポーザル" : "My Proposals",
        user: user,
        language: language,
        currentPath: "/my-proposals"
      ) {
        MyProposalsPageView(user: user, proposals: proposals, language: language)
      }
    }
  }

  private func renderMyProposalDetailPage(req: Request, language: CfPLanguage) async throws
    -> HTMLResponse
  {
    let user = try? await getAuthenticatedUser(req: req)
    var proposal: ProposalDTO?

    if let user {
      if let proposalIDString = req.parameters.get("proposalID"),
        let proposalID = UUID(uuidString: proposalIDString)
      {
        // Fetch proposal and verify it belongs to the current user
        if let dbProposal = try await Proposal.query(on: req.db)
          .filter(\.$id == proposalID)
          .filter(\.$speaker.$id == user.id)
          .with(\.$conference)
          .first()
        {
          proposal = try dbProposal.toDTO(
            speakerUsername: user.username,
            conference: dbProposal.conference
          )
        }
      }
    }

    return HTMLResponse {
      CfPLayout(
        title: proposal?.title ?? (language == .ja ? "プロポーザル詳細" : "Proposal Detail"),
        user: user,
        language: language,
        currentPath: "/my-proposals"
      ) {
        MyProposalDetailPageView(user: user, proposal: proposal, language: language)
      }
    }
  }

  @Sendable
  func profilePage(req: Request) async throws -> Response {
    guard let user = try? await getAuthenticatedUser(req: req) else {
      return req.redirect(to: "/api/v1/auth/github?returnTo=/profile")
    }

    let returnTo = req.query[String.self, at: "returnTo"]
    let success = req.query[String.self, at: "success"] == "true"

    let html = HTMLResponse {
      CfPLayout(title: "Profile Setup", user: user) {
        ProfileSetupPageView(
          user: user,
          successMessage: success ? "Profile updated successfully!" : nil,
          returnTo: returnTo
        )
      }
    }
    return try await html.encodeResponse(for: req)
  }

  // MARK: - Form Handlers

  @Sendable
  func handleUpdateProfile(req: Request) async throws -> Response {
    guard let user = try? await getAuthenticatedUser(req: req) else {
      return req.redirect(to: "/api/v1/auth/github?returnTo=/profile")
    }

    // Decode form data
    struct ProfileFormData: Content {
      var displayName: String
      var email: String
      var bio: String
      var avatarURL: String
      var returnTo: String?
    }

    let formData: ProfileFormData
    do {
      formData = try req.content.decode(ProfileFormData.self)
    } catch {
      return try await renderProfilePageWithError(
        req: req, user: user, error: "Invalid form data", returnTo: nil)
    }

    // Validate
    guard !formData.displayName.isEmpty else {
      return try await renderProfilePageWithError(
        req: req, user: user, error: "Name is required", returnTo: formData.returnTo)
    }
    guard !formData.email.isEmpty else {
      return try await renderProfilePageWithError(
        req: req, user: user, error: "Email is required", returnTo: formData.returnTo)
    }
    guard !formData.bio.isEmpty else {
      return try await renderProfilePageWithError(
        req: req, user: user, error: "Bio is required", returnTo: formData.returnTo)
    }
    guard !formData.avatarURL.isEmpty else {
      return try await renderProfilePageWithError(
        req: req, user: user, error: "Profile picture URL is required", returnTo: formData.returnTo)
    }

    // Update user in database
    guard let dbUser = try await User.find(user.id, on: req.db) else {
      return try await renderProfilePageWithError(
        req: req, user: user, error: "User not found", returnTo: formData.returnTo)
    }

    dbUser.displayName = formData.displayName
    dbUser.email = formData.email
    dbUser.bio = formData.bio
    dbUser.avatarURL = formData.avatarURL
    try await dbUser.save(on: req.db)

    // Redirect to returnTo or submit page
    let returnTo = formData.returnTo ?? "/submit"
    return req.redirect(to: returnTo)
  }

  private func renderProfilePageWithError(
    req: Request, user: UserDTO, error: String, returnTo: String?
  ) async throws -> Response {
    let html = HTMLResponse {
      CfPLayout(title: "Profile Setup", user: user) {
        ProfileSetupPageView(user: user, errorMessage: error, returnTo: returnTo)
      }
    }
    return try await html.encodeResponse(for: req)
  }

  @Sendable
  func handleSubmitProposal(req: Request) async throws -> Response {
    try await processSubmitProposal(req: req, language: .en)
  }

  @Sendable
  func handleSubmitProposalJa(req: Request) async throws -> Response {
    try await processSubmitProposal(req: req, language: .ja)
  }

  private func processSubmitProposal(req: Request, language: CfPLanguage) async throws -> Response {
    guard let user = try? await getAuthenticatedUser(req: req) else {
      return req.redirect(to: "/api/v1/auth/github?returnTo=\(language.path(for: "/submit"))")
    }

    // Decode form data
    struct ProposalFormData: Content {
      var title: String
      var abstract: String
      var talkDetails: String
      var talkDuration: String
      var speakerName: String
      var speakerEmail: String
      var bio: String
      var iconUrl: String
      var notesToOrganizers: String?
    }

    let formData: ProposalFormData
    do {
      formData = try req.content.decode(ProposalFormData.self)
    } catch {
      return try await renderSubmitPageWithError(
        req: req,
        user: user,
        error: language == .ja ? "フォームデータが無効です" : "Invalid form data",
        language: language
      )
    }

    // Validate
    guard !formData.title.isEmpty else {
      return try await renderSubmitPageWithError(
        req: req,
        user: user,
        error: language == .ja ? "タイトルは必須です" : "Title is required",
        language: language
      )
    }
    guard !formData.abstract.isEmpty else {
      return try await renderSubmitPageWithError(
        req: req,
        user: user,
        error: language == .ja ? "概要は必須です" : "Abstract is required",
        language: language
      )
    }
    guard !formData.talkDetails.isEmpty else {
      return try await renderSubmitPageWithError(
        req: req,
        user: user,
        error: language == .ja ? "トークの詳細は必須です" : "Talk details are required",
        language: language
      )
    }
    guard !formData.speakerName.isEmpty else {
      return try await renderSubmitPageWithError(
        req: req,
        user: user,
        error: language == .ja ? "スピーカー名は必須です" : "Speaker name is required",
        language: language
      )
    }
    guard !formData.speakerEmail.isEmpty else {
      return try await renderSubmitPageWithError(
        req: req,
        user: user,
        error: language == .ja ? "スピーカーメールは必須です" : "Speaker email is required",
        language: language
      )
    }
    guard !formData.bio.isEmpty else {
      return try await renderSubmitPageWithError(
        req: req,
        user: user,
        error: language == .ja ? "スピーカー自己紹介は必須です" : "Speaker bio is required",
        language: language
      )
    }
    guard !formData.iconUrl.isEmpty else {
      return try await renderSubmitPageWithError(
        req: req,
        user: user,
        error: language == .ja ? "プロフィール画像URLは必須です" : "Profile picture URL is required",
        language: language
      )
    }

    guard let talkDuration = TalkDuration(rawValue: formData.talkDuration) else {
      return try await renderSubmitPageWithError(
        req: req,
        user: user,
        error: language == .ja ? "トーク時間を選択してください" : "Please select a talk duration",
        language: language
      )
    }

    // Find current open conference
    guard
      let conference = try await Conference.query(on: req.db)
        .filter(\.$isOpen == true)
        .sort(\.$year, .descending)
        .first()
    else {
      return try await renderSubmitPageWithError(
        req: req,
        user: user,
        error: language == .ja
          ? "現在プロポーザルの募集は行っていません。次回のカンファレンスをお待ちください。"
          : "The Call for Proposals is not currently open. Please check back later for the next conference.",
        language: language
      )
    }

    guard let conferenceID = conference.id else {
      return try await renderSubmitPageWithError(
        req: req,
        user: user,
        error: language == .ja ? "カンファレンスの設定エラー" : "Conference configuration error",
        language: language
      )
    }

    // Create proposal
    let proposal = Proposal(
      conferenceID: conferenceID,
      title: formData.title,
      abstract: formData.abstract,
      talkDetail: formData.talkDetails,
      talkDuration: talkDuration,
      speakerName: formData.speakerName,
      speakerEmail: formData.speakerEmail,
      bio: formData.bio,
      iconURL: formData.iconUrl,
      notes: formData.notesToOrganizers?.isEmpty == true ? nil : formData.notesToOrganizers,
      speakerID: user.id
    )

    try await proposal.save(on: req.db)

    // Redirect to success page
    return req.redirect(to: "\(language.path(for: "/submit"))?success=true")
  }

  private func renderSubmitPageWithError(
    req: Request,
    user: UserDTO,
    error: String,
    language: CfPLanguage
  ) async throws -> Response {
    let html = HTMLResponse {
      CfPLayout(
        title: language == .ja ? "プロポーザルを提出" : "Submit Proposal",
        user: user,
        language: language,
        currentPath: "/submit"
      ) {
        SubmitPageView(user: user, success: false, errorMessage: error, language: language)
      }
    }
    return try await html.encodeResponse(for: req)
  }

  // MARK: - Logout

  @Sendable
  func logout(req: Request) async throws -> Response {
    performLogout(req: req, language: .en)
  }

  @Sendable
  func logoutJa(req: Request) async throws -> Response {
    performLogout(req: req, language: .ja)
  }

  private func performLogout(req: Request, language: CfPLanguage) -> Response {
    let response = req.redirect(to: language.path(for: "/"))

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
    let conferencePath = req.query[String.self, at: "conference"]

    // Get proposals (filtered by conference if specified)
    var proposals: [ProposalDTO] = []
    if let user, user.role == .admin {
      let query = Proposal.query(on: req.db)
        .with(\.$speaker)
        .with(\.$conference)
        .sort(\.$createdAt, .descending)

      if let conferencePath {
        if let conference = try await Conference.query(on: req.db)
          .filter(\.$path == conferencePath)
          .first(),
          let conferenceID = conference.id
        {
          query.filter(\.$conference.$id == conferenceID)
        }
      }

      let dbProposals = try await query.all()
      proposals = try dbProposals.map {
        try $0.toDTO(speakerUsername: $0.speaker.username, conference: $0.conference)
      }
    }

    return HTMLResponse {
      CfPLayout(title: "Organizer - Proposals", user: user) {
        OrganizerProposalsPageView(
          user: user,
          proposals: proposals,
          conferencePath: conferencePath
        )
      }
    }
  }

  @Sendable
  func organizerProposalDetailPage(req: Request) async throws -> HTMLResponse {
    let user = try? await getAuthenticatedUser(req: req)
    var proposal: ProposalDTO?

    if let user, user.role == .admin {
      if let proposalIDString = req.parameters.get("proposalID"),
        let proposalID = UUID(uuidString: proposalIDString)
      {
        if let dbProposal = try await Proposal.query(on: req.db)
          .filter(\.$id == proposalID)
          .with(\.$speaker)
          .with(\.$conference)
          .first()
        {
          proposal = try dbProposal.toDTO(
            speakerUsername: dbProposal.speaker.username,
            conference: dbProposal.conference
          )
        }
      }
    }

    return HTMLResponse {
      CfPLayout(title: proposal?.title ?? "Proposal Detail", user: user) {
        OrganizerProposalDetailPageView(user: user, proposal: proposal)
      }
    }
  }

  @Sendable
  func organizerExportProposalsCSV(req: Request) async throws -> Response {
    guard let user = try? await getAuthenticatedUser(req: req), user.role == .admin else {
      throw Abort(.unauthorized, reason: "Admin access required")
    }

    let conferencePath = req.query[String.self, at: "conference"]

    // Build query
    let query = Proposal.query(on: req.db)
      .with(\.$speaker)
      .with(\.$conference)
      .sort(\.$createdAt, .descending)

    if let conferencePath {
      if let conference = try await Conference.query(on: req.db)
        .filter(\.$path == conferencePath)
        .first(),
        let conferenceID = conference.id
      {
        query.filter(\.$conference.$id == conferenceID)
      }
    }

    let dbProposals = try await query.all()

    // Build CSV
    var csv =
      "ID,Title,Abstract,Talk Details,Duration,Speaker Name,Speaker Email,Speaker Username,Bio,Icon URL,Notes,Conference,Submitted At\n"

    let dateFormatter = ISO8601DateFormatter()

    for proposal in dbProposals {
      let columns = [
        proposal.id?.uuidString ?? "",
        escapeCSV(proposal.title),
        escapeCSV(proposal.abstract),
        escapeCSV(proposal.talkDetail),
        proposal.talkDuration.rawValue,
        escapeCSV(proposal.speakerName),
        escapeCSV(proposal.speakerEmail),
        proposal.speaker.username,
        escapeCSV(proposal.bio),
        proposal.iconURL ?? "",
        escapeCSV(proposal.notes ?? ""),
        proposal.conference.displayName,
        proposal.createdAt.map { dateFormatter.string(from: $0) } ?? "",
      ]
      csv += columns.joined(separator: ",") + "\n"
    }

    var headers = HTTPHeaders()
    headers.add(name: .contentType, value: "text/csv; charset=utf-8")
    headers.add(
      name: .contentDisposition,
      value: "attachment; filename=\"proposals-\(conferencePath ?? "all").csv\""
    )

    return Response(status: .ok, headers: headers, body: .init(string: csv))
  }

  private func escapeCSV(_ value: String) -> String {
    let needsQuoting =
      value.contains(",") || value.contains("\"") || value.contains("\n")
      || value.contains("\r")
    if needsQuoting {
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
