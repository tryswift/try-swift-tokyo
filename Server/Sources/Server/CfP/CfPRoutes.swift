import Fluent
import JWT
import SharedModels
import Vapor
import VaporElementary

/// Routes for CfP SSR pages
struct CfPRoutes: RouteCollection {
  func boot(routes: RoutesBuilder) throws {
    let cfp = routes.grouped("cfp")

    // English routes (default)
    cfp.get(use: homePage)
    cfp.get("guidelines", use: guidelinesPage)
    cfp.get("login", use: loginPage)
    cfp.get("login-page", use: loginPage)  // Backward compatibility
    cfp.get("submit", use: submitPage)
    cfp.get("submit-page", use: submitPage)  // Backward compatibility
    cfp.get("my-proposals", use: myProposalsPage)
    cfp.get("my-proposals-page", use: myProposalsPage)  // Backward compatibility
    cfp.post("submit", use: handleSubmitProposal)
    cfp.get("logout", use: logout)

    // Japanese routes
    let ja = cfp.grouped("ja")
    ja.get(use: homePageJa)
    ja.get("guidelines", use: guidelinesPageJa)
    ja.get("login", use: loginPageJa)
    ja.get("submit", use: submitPageJa)
    ja.get("my-proposals", use: myProposalsPageJa)
    ja.post("submit", use: handleSubmitProposalJa)
    ja.get("logout", use: logoutJa)
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
  func loginPage(req: Request) async throws -> HTMLResponse {
    try await renderLoginPage(req: req, language: .en)
  }

  @Sendable
  func submitPage(req: Request) async throws -> HTMLResponse {
    try await renderSubmitPage(req: req, language: .en)
  }

  @Sendable
  func myProposalsPage(req: Request) async throws -> HTMLResponse {
    try await renderMyProposalsPage(req: req, language: .en)
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

  private func renderGuidelinesPage(req: Request, language: CfPLanguage) async throws -> HTMLResponse {
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

  private func renderMyProposalsPage(req: Request, language: CfPLanguage) async throws -> HTMLResponse {
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

  // MARK: - Form Handlers

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
      var bio: String
      var iconUrl: String?
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
    guard !formData.bio.isEmpty else {
      return try await renderSubmitPageWithError(
        req: req,
        user: user,
        error: language == .ja ? "スピーカー自己紹介は必須です" : "Speaker bio is required",
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
      bio: formData.bio,
      iconURL: formData.iconUrl?.isEmpty == true ? nil : formData.iconUrl,
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
