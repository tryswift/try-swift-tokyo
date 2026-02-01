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
    routes.get("my-proposals", ":proposalID", "edit", use: editProposalPage)
    routes.post("my-proposals", ":proposalID", "edit", use: handleEditProposal)
    routes.post("my-proposals", ":proposalID", "withdraw", use: handleWithdrawProposal)

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
    ja.get("my-proposals", ":proposalID", "edit", use: editProposalPageJa)
    ja.post("my-proposals", ":proposalID", "edit", use: handleEditProposalJa)
    ja.post("my-proposals", ":proposalID", "withdraw", use: handleWithdrawProposalJa)
    ja.post("submit", use: handleSubmitProposalJa)
    ja.get("logout", use: logoutJa)

    // Organizer pages
    let organizer = routes.grouped("organizer")
    organizer.get("proposals", use: organizerProposalsPage)
    organizer.get("proposals", "export", use: organizerExportProposalsCSV)
    organizer.get("proposals", "import", use: organizerImportPage)
    organizer.post("proposals", "import", use: handleImportCSV)
    organizer.get("proposals", ":proposalID", use: organizerProposalDetailPage)
    organizer.get("proposals", ":proposalID", "edit", use: organizerEditProposalPage)
    organizer.post("proposals", ":proposalID", "edit", use: handleOrganizerEditProposal)
    organizer.post("proposals", ":proposalID", "accept", use: handleAcceptProposal)
    organizer.post("proposals", ":proposalID", "reject", use: handleRejectProposal)
    organizer.post("proposals", ":proposalID", "revert-status", use: handleRevertProposalStatus)

    // Timetable editor
    organizer.get("timetable", use: timetableEditorPage)
    organizer.get("timetable", "api", "slots", use: getTimetableSlots)
    organizer.post("timetable", "api", "slots", use: createSlot)
    organizer.post("timetable", "api", "slots", ":slotID", use: updateSlot)
    organizer.post("timetable", "api", "slots", ":slotID", "delete", use: deleteSlot)
    organizer.post("timetable", "api", "reorder", use: reorderSlots)
    organizer.get("timetable", "export", use: exportAllTimetableJSON)
    organizer.get("timetable", "export", ":day", use: exportTimetableJSON)

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

  @Sendable
  func editProposalPage(req: Request) async throws -> HTMLResponse {
    try await renderEditProposalPage(req: req, language: .en)
  }

  @Sendable
  func handleEditProposal(req: Request) async throws -> Response {
    try await processEditProposal(req: req, language: .en)
  }

  @Sendable
  func handleWithdrawProposal(req: Request) async throws -> Response {
    try await processWithdrawProposal(req: req, language: .en)
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

  @Sendable
  func editProposalPageJa(req: Request) async throws -> HTMLResponse {
    try await renderEditProposalPage(req: req, language: .ja)
  }

  @Sendable
  func handleEditProposalJa(req: Request) async throws -> Response {
    try await processEditProposal(req: req, language: .ja)
  }

  @Sendable
  func handleWithdrawProposalJa(req: Request) async throws -> Response {
    try await processWithdrawProposal(req: req, language: .ja)
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
    let showWithdrawnMessage = req.query[String.self, at: "withdrawn"] == "true"

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
        MyProposalsPageView(
          user: user, proposals: proposals, language: language,
          showWithdrawnMessage: showWithdrawnMessage)
      }
    }
  }

  private func renderMyProposalDetailPage(req: Request, language: CfPLanguage) async throws
    -> HTMLResponse
  {
    let user = try? await getAuthenticatedUser(req: req)
    var proposal: ProposalDTO?
    let showUpdatedMessage = req.query[String.self, at: "updated"] == "true"

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
        MyProposalDetailPageView(
          user: user, proposal: proposal, language: language,
          showUpdatedMessage: showUpdatedMessage)
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

    // Validate that only invited speakers can submit invited talks
    if talkDuration.isInvitedOnly && !user.role.isInvitedSpeaker {
      return try await renderSubmitPageWithError(
        req: req,
        user: user,
        error: language == .ja
          ? "招待スピーカーセッションは招待スピーカーのみが提出できます"
          : "Only invited speakers can submit invited talks",
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

    // Notify organizers via Slack
    await SlackNotifier.notifyNewProposal(
      title: formData.title,
      speakerName: formData.speakerName,
      talkDuration: talkDuration.rawValue,
      client: req.client,
      logger: req.logger
    )

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

  // MARK: - Edit Proposal

  private func renderEditProposalPage(req: Request, language: CfPLanguage) async throws
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
        title: language == .ja ? "プロポーザルを編集" : "Edit Proposal",
        user: user,
        language: language,
        currentPath: "/my-proposals"
      ) {
        EditProposalPageView(user: user, proposal: proposal, language: language)
      }
    }
  }

  private func processEditProposal(req: Request, language: CfPLanguage) async throws -> Response {
    // 1. Authentication check
    guard let user = try? await getAuthenticatedUser(req: req) else {
      return req.redirect(to: "/api/v1/auth/github?returnTo=\(language.path(for: "/my-proposals"))")
    }

    // 2. Get proposal ID
    guard let proposalIDString = req.parameters.get("proposalID"),
      let proposalID = UUID(uuidString: proposalIDString)
    else {
      throw Abort(.badRequest, reason: "Invalid proposal ID")
    }

    // 3. Fetch proposal and verify ownership
    guard
      let proposal = try await Proposal.query(on: req.db)
        .filter(\.$id == proposalID)
        .filter(\.$speaker.$id == user.id)
        .with(\.$conference)
        .first()
    else {
      throw Abort(
        .notFound, reason: language == .ja ? "プロポーザルが見つかりません" : "Proposal not found")
    }

    // 4. Decode form data
    struct EditFormData: Content {
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

    let formData: EditFormData
    do {
      formData = try req.content.decode(EditFormData.self)
    } catch {
      return try await renderEditProposalPageWithError(
        req: req, user: user, proposal: proposal,
        error: language == .ja ? "フォームデータが無効です" : "Invalid form data",
        language: language
      )
    }

    // 5. Validation
    guard !formData.title.isEmpty else {
      return try await renderEditProposalPageWithError(
        req: req, user: user, proposal: proposal,
        error: language == .ja ? "タイトルは必須です" : "Title is required",
        language: language
      )
    }
    guard !formData.abstract.isEmpty else {
      return try await renderEditProposalPageWithError(
        req: req, user: user, proposal: proposal,
        error: language == .ja ? "概要は必須です" : "Abstract is required",
        language: language
      )
    }
    guard !formData.talkDetails.isEmpty else {
      return try await renderEditProposalPageWithError(
        req: req, user: user, proposal: proposal,
        error: language == .ja ? "トークの詳細は必須です" : "Talk details are required",
        language: language
      )
    }
    guard !formData.speakerName.isEmpty else {
      return try await renderEditProposalPageWithError(
        req: req, user: user, proposal: proposal,
        error: language == .ja ? "スピーカー名は必須です" : "Speaker name is required",
        language: language
      )
    }
    guard !formData.speakerEmail.isEmpty else {
      return try await renderEditProposalPageWithError(
        req: req, user: user, proposal: proposal,
        error: language == .ja ? "スピーカーメールは必須です" : "Speaker email is required",
        language: language
      )
    }
    guard !formData.bio.isEmpty else {
      return try await renderEditProposalPageWithError(
        req: req, user: user, proposal: proposal,
        error: language == .ja ? "スピーカー自己紹介は必須です" : "Speaker bio is required",
        language: language
      )
    }
    guard !formData.iconUrl.isEmpty else {
      return try await renderEditProposalPageWithError(
        req: req, user: user, proposal: proposal,
        error: language == .ja ? "プロフィール画像URLは必須です" : "Profile picture URL is required",
        language: language
      )
    }

    guard let talkDuration = TalkDuration(rawValue: formData.talkDuration) else {
      return try await renderEditProposalPageWithError(
        req: req, user: user, proposal: proposal,
        error: language == .ja ? "トーク時間を選択してください" : "Please select a talk duration",
        language: language
      )
    }

    // 6. Update proposal
    proposal.title = formData.title
    proposal.abstract = formData.abstract
    proposal.talkDetail = formData.talkDetails
    proposal.talkDuration = talkDuration
    proposal.speakerName = formData.speakerName
    proposal.speakerEmail = formData.speakerEmail
    proposal.bio = formData.bio
    proposal.iconURL = formData.iconUrl
    proposal.notes =
      formData.notesToOrganizers?.isEmpty == true ? nil : formData.notesToOrganizers

    try await proposal.save(on: req.db)

    // 7. Redirect to detail page with success message
    return req.redirect(
      to: "\(language.path(for: "/my-proposals/\(proposalID.uuidString)"))?updated=true")
  }

  private func renderEditProposalPageWithError(
    req: Request,
    user: UserDTO,
    proposal: Proposal,
    error: String,
    language: CfPLanguage
  ) async throws -> Response {
    let proposalDTO = try proposal.toDTO(
      speakerUsername: user.username,
      conference: proposal.conference
    )
    let html = HTMLResponse {
      CfPLayout(
        title: language == .ja ? "プロポーザルを編集" : "Edit Proposal",
        user: user,
        language: language,
        currentPath: "/my-proposals"
      ) {
        EditProposalPageView(
          user: user, proposal: proposalDTO, errorMessage: error, language: language)
      }
    }
    return try await html.encodeResponse(for: req)
  }

  // MARK: - Withdraw Proposal

  private func processWithdrawProposal(req: Request, language: CfPLanguage) async throws
    -> Response
  {
    // 1. Authentication check
    guard let user = try? await getAuthenticatedUser(req: req) else {
      return req.redirect(to: "/api/v1/auth/github?returnTo=\(language.path(for: "/my-proposals"))")
    }

    // 2. Get proposal ID
    guard let proposalIDString = req.parameters.get("proposalID"),
      let proposalID = UUID(uuidString: proposalIDString)
    else {
      throw Abort(.badRequest, reason: "Invalid proposal ID")
    }

    // 3. Fetch proposal and verify ownership
    guard
      let proposal = try await Proposal.query(on: req.db)
        .filter(\.$id == proposalID)
        .filter(\.$speaker.$id == user.id)
        .first()
    else {
      throw Abort(
        .notFound, reason: language == .ja ? "プロポーザルが見つかりません" : "Proposal not found")
    }

    // 4. Delete proposal
    try await proposal.delete(on: req.db)

    // 5. Redirect to my-proposals with success message
    return req.redirect(to: "\(language.path(for: "/my-proposals"))?withdrawn=true")
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
      "ID,Title,Abstract,Talk Details,Duration,Status,Speaker Name,Speaker Email,Speaker Username,Bio,Icon URL,Notes,Conference,Submitted At\n"

    let dateFormatter = ISO8601DateFormatter()

    for proposal in dbProposals {
      let columns = [
        proposal.id?.uuidString ?? "",
        escapeCSV(proposal.title),
        escapeCSV(proposal.abstract),
        escapeCSV(proposal.talkDetail),
        proposal.talkDuration.rawValue,
        proposal.status.rawValue,
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

  // MARK: - Accept/Reject Proposals

  @Sendable
  func handleAcceptProposal(req: Request) async throws -> Response {
    try await changeProposalStatus(req: req, newStatus: .accepted)
  }

  @Sendable
  func handleRejectProposal(req: Request) async throws -> Response {
    try await changeProposalStatus(req: req, newStatus: .rejected)
  }

  @Sendable
  func handleRevertProposalStatus(req: Request) async throws -> Response {
    try await changeProposalStatus(req: req, newStatus: .submitted)
  }

  private func changeProposalStatus(req: Request, newStatus: ProposalStatus) async throws
    -> Response
  {
    guard let user = try? await getAuthenticatedUser(req: req), user.role == .admin else {
      throw Abort(.unauthorized, reason: "Admin access required")
    }

    guard let proposalIDString = req.parameters.get("proposalID"),
      let proposalID = UUID(uuidString: proposalIDString)
    else {
      throw Abort(.badRequest, reason: "Invalid proposal ID")
    }

    guard let proposal = try await Proposal.find(proposalID, on: req.db) else {
      throw Abort(.notFound, reason: "Proposal not found")
    }

    proposal.status = newStatus
    try await proposal.save(on: req.db)

    return req.redirect(to: "/organizer/proposals/\(proposalID)")
  }

  // MARK: - Import Speaker Candidates

  @Sendable
  func organizerImportPage(req: Request) async throws -> HTMLResponse {
    let user = try? await getAuthenticatedUser(req: req)

    // Get available conferences for selection
    var conferences: [ConferencePublicInfo] = []
    if let user, user.role == .admin {
      conferences = try await Conference.query(on: req.db)
        .sort(\.$year, .descending)
        .all()
        .map { $0.toPublicInfo() }
    }

    // Check for import result query params
    let importedCount = req.query[Int.self, at: "imported"]
    let skippedCount = req.query[Int.self, at: "skipped"]
    let errorCount = req.query[Int.self, at: "errors"]
    let errorMessage =
      req.query[String.self, at: "error"]
      ?? (errorCount.map { $0 > 0 ? "\($0) rows had errors during import" : nil } ?? nil)

    return HTMLResponse {
      CfPLayout(title: "Import Speaker Candidates", user: user) {
        ImportSpeakersPageView(
          user: user,
          conferences: conferences,
          errorMessage: errorMessage,
          importedCount: importedCount,
          skippedCount: skippedCount
        )
      }
    }
  }

  @Sendable
  func handleImportCSV(req: Request) async throws -> Response {
    guard let user = try? await getAuthenticatedUser(req: req), user.role == .admin else {
      throw Abort(.unauthorized, reason: "Admin access required")
    }

    // Decode multipart form data
    struct ImportFormData: Content {
      var csvFile: File
      var conferenceId: UUID
      var skipDuplicates: String?
    }

    let formData: ImportFormData
    do {
      formData = try req.content.decode(ImportFormData.self)
    } catch {
      return req.redirect(to: "/organizer/proposals/import?error=Invalid+form+data")
    }

    // Validate file
    guard formData.csvFile.filename.hasSuffix(".csv") else {
      return req.redirect(to: "/organizer/proposals/import?error=Please+upload+a+CSV+file")
    }

    // Parse CSV content
    let csvContent = String(buffer: formData.csvFile.data)
    let candidates: [SpeakerCandidate]
    do {
      candidates = try SpeakersCSVParser.parse(csvContent)
    } catch {
      let errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
      let encodedError =
        errorMessage.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        ?? "Parse+error"
      return req.redirect(to: "/organizer/proposals/import?error=\(encodedError)")
    }

    // Get conference
    guard let conference = try await Conference.find(formData.conferenceId, on: req.db) else {
      return req.redirect(to: "/organizer/proposals/import?error=Conference+not+found")
    }

    guard let conferenceID = conference.id else {
      return req.redirect(to: "/organizer/proposals/import?error=Conference+ID+missing")
    }

    // Get import system user
    guard
      let importUser = try await User.find(
        AddPaperCallImportUser.paperCallUserID,
        on: req.db
      )
    else {
      return req.redirect(
        to: "/organizer/proposals/import?error=Import+user+not+configured.+Run+migrations+first.")
    }

    guard let importUserID = importUser.id else {
      return req.redirect(to: "/organizer/proposals/import?error=Import+user+ID+missing")
    }

    // Import candidates
    let skipDuplicates = formData.skipDuplicates == "true"
    var importedCount = 0
    var skippedCount = 0
    var errorCount = 0

    for candidate in candidates {
      do {
        // Check for duplicate (by speaker email + title)
        if skipDuplicates {
          let existing = try await Proposal.query(on: req.db)
            .filter(\.$speakerEmail == candidate.email)
            .filter(\.$title == candidate.title)
            .filter(\.$conference.$id == conferenceID)
            .first()
          if existing != nil {
            skippedCount += 1
            continue
          }
        }

        let notes = SpeakersCSVParser.buildNotes(from: candidate)
        let githubUsername = SpeakersCSVParser.extractGitHubUsername(from: candidate.github)
        let iconURL = SpeakersCSVParser.githubAvatarURL(from: candidate.github)

        let proposal = Proposal(
          conferenceID: conferenceID,
          title: candidate.title,
          abstract: candidate.summary,
          talkDetail: candidate.talkDetail,
          talkDuration: .regular,
          speakerName: candidate.name,
          speakerEmail: candidate.email,
          bio: candidate.bio,
          iconURL: iconURL,
          notes: notes.isEmpty ? nil : notes,
          speakerID: importUserID
        )
        proposal.paperCallUsername = githubUsername.isEmpty ? nil : githubUsername

        try await proposal.save(on: req.db)
        importedCount += 1
      } catch {
        errorCount += 1
        req.logger.error("Failed to import candidate: \(error.localizedDescription)")
      }
    }

    // Redirect with results
    return req.redirect(
      to:
        "/organizer/proposals/import?imported=\(importedCount)&skipped=\(skippedCount)&errors=\(errorCount)"
    )
  }

  // MARK: - Organizer Edit Proposal

  @Sendable
  func organizerEditProposalPage(req: Request) async throws -> HTMLResponse {
    let user = try? await getAuthenticatedUser(req: req)
    var proposal: ProposalDTO?
    var conferences: [ConferencePublicInfo] = []

    if let user, user.role == .admin {
      conferences = try await Conference.query(on: req.db)
        .sort(\.$year, .descending)
        .all()
        .map { $0.toPublicInfo() }

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
            speakerUsername: dbProposal.paperCallUsername ?? dbProposal.speaker.username,
            conference: dbProposal.conference
          )
        }
      }
    }

    return HTMLResponse {
      CfPLayout(title: "Edit Proposal (Organizer)", user: user) {
        OrganizerEditProposalPageView(
          user: user,
          proposal: proposal,
          conferences: conferences
        )
      }
    }
  }

  @Sendable
  func handleOrganizerEditProposal(req: Request) async throws -> Response {
    guard let user = try? await getAuthenticatedUser(req: req), user.role == .admin else {
      throw Abort(.unauthorized, reason: "Admin access required")
    }

    guard let proposalIDString = req.parameters.get("proposalID"),
      let proposalID = UUID(uuidString: proposalIDString)
    else {
      throw Abort(.badRequest, reason: "Invalid proposal ID")
    }

    guard
      let proposal = try await Proposal.query(on: req.db)
        .filter(\.$id == proposalID)
        .with(\.$conference)
        .first()
    else {
      throw Abort(.notFound, reason: "Proposal not found")
    }

    // Decode form data
    struct OrganizerEditFormData: Content {
      var conferenceId: UUID
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

    let formData: OrganizerEditFormData
    do {
      formData = try req.content.decode(OrganizerEditFormData.self)
    } catch {
      throw Abort(.badRequest, reason: "Invalid form data")
    }

    // Validate required fields
    guard !formData.title.isEmpty else {
      throw Abort(.badRequest, reason: "Title is required")
    }
    guard !formData.abstract.isEmpty else {
      throw Abort(.badRequest, reason: "Abstract is required")
    }
    guard !formData.talkDetails.isEmpty else {
      throw Abort(.badRequest, reason: "Talk details are required")
    }
    guard !formData.speakerName.isEmpty else {
      throw Abort(.badRequest, reason: "Speaker name is required")
    }
    guard !formData.speakerEmail.isEmpty else {
      throw Abort(.badRequest, reason: "Speaker email is required")
    }
    guard !formData.bio.isEmpty else {
      throw Abort(.badRequest, reason: "Speaker bio is required")
    }

    guard let talkDuration = TalkDuration(rawValue: formData.talkDuration) else {
      throw Abort(.badRequest, reason: "Invalid talk duration")
    }

    // Update proposal
    proposal.$conference.id = formData.conferenceId
    proposal.title = formData.title
    proposal.abstract = formData.abstract
    proposal.talkDetail = formData.talkDetails
    proposal.talkDuration = talkDuration
    proposal.speakerName = formData.speakerName
    proposal.speakerEmail = formData.speakerEmail
    proposal.bio = formData.bio
    proposal.iconURL = formData.iconUrl.isEmpty ? nil : formData.iconUrl
    proposal.notes = formData.notesToOrganizers?.isEmpty == true ? nil : formData.notesToOrganizers

    try await proposal.save(on: req.db)

    return req.redirect(to: "/organizer/proposals/\(proposalID)?updated=true")
  }

  // MARK: - Timetable Editor

  @Sendable
  func timetableEditorPage(req: Request) async throws -> HTMLResponse {
    let user = try? await getAuthenticatedUser(req: req)

    guard let user, user.role == .admin else {
      return HTMLResponse {
        CfPLayout(title: "Timetable Editor", user: user) {
          TimetableEditorPageView(
            user: user,
            conference: nil,
            acceptedProposals: [],
            slots: [],
            days: []
          )
        }
      }
    }

    // Get latest conference
    guard
      let conference = try await Conference.query(on: req.db)
        .sort(\.$year, .descending)
        .first(),
      let conferenceID = conference.id
    else {
      throw Abort(.notFound, reason: "No conference found")
    }

    // Get accepted proposals
    let allAccepted = try await Proposal.query(on: req.db)
      .filter(\.$conference.$id == conferenceID)
      .filter(\.$status == .accepted)
      .with(\.$conference)
      .with(\.$speaker)
      .sort(\.$talkDuration)
      .sort(\.$speakerName)
      .all()

    let acceptedDTOs = try allAccepted.map {
      try $0.toDTO(
        speakerUsername: $0.paperCallUsername ?? $0.speaker.username,
        conference: $0.conference)
    }

    // Get existing schedule slots
    let slots = try await ScheduleSlot.query(on: req.db)
      .filter(\.$conference.$id == conferenceID)
      .with(\.$proposal) { proposal in
        proposal.with(\.$speaker)
        proposal.with(\.$conference)
      }
      .sort(\.$day)
      .sort(\.$sortOrder)
      .all()

    let days = computeConferenceDays(conference: conference)

    let slotDTOs = try slots.map { slot -> ScheduleSlotDTO in
      try ScheduleSlotDTO(slot: slot)
    }

    // Proposals already assigned to slots
    let assignedProposalIDs = Set(slots.compactMap { $0.$proposal.id })
    let unassignedProposals = acceptedDTOs.filter { !assignedProposalIDs.contains($0.id) }

    return HTMLResponse {
      CfPLayout(title: "Timetable Editor", user: user) {
        TimetableEditorPageView(
          user: user,
          conference: conference.toPublicInfo(),
          acceptedProposals: unassignedProposals,
          slots: slotDTOs,
          days: days
        )
      }
    }
  }

  @Sendable
  func getTimetableSlots(req: Request) async throws -> Response {
    guard let user = try? await getAuthenticatedUser(req: req), user.role == .admin else {
      throw Abort(.unauthorized, reason: "Admin access required")
    }

    guard
      let conference = try await Conference.query(on: req.db)
        .sort(\.$year, .descending)
        .first(),
      let conferenceID = conference.id
    else {
      throw Abort(.notFound, reason: "No conference found")
    }

    let slots = try await ScheduleSlot.query(on: req.db)
      .filter(\.$conference.$id == conferenceID)
      .with(\.$proposal) { proposal in
        proposal.with(\.$speaker)
        proposal.with(\.$conference)
      }
      .sort(\.$day)
      .sort(\.$sortOrder)
      .all()

    let slotDTOs = try slots.map { try ScheduleSlotDTO(slot: $0) }

    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    let data = try encoder.encode(slotDTOs)

    var headers = HTTPHeaders()
    headers.contentType = .json
    return Response(status: .ok, headers: headers, body: .init(data: data))
  }

  @Sendable
  func createSlot(req: Request) async throws -> Response {
    guard let user = try? await getAuthenticatedUser(req: req), user.role == .admin else {
      throw Abort(.unauthorized, reason: "Admin access required")
    }

    struct CreateSlotRequest: Content {
      var conferenceId: UUID
      var proposalId: UUID?
      var day: Int
      var startTime: String
      var endTime: String?
      var slotType: String
      var customTitle: String?
      var customTitleJa: String?
      var place: String?
      var placeJa: String?
    }

    let body = try req.content.decode(CreateSlotRequest.self)

    guard let slotType = SlotType(rawValue: body.slotType) else {
      throw Abort(.badRequest, reason: "Invalid slot type")
    }

    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime]
    guard let startTime = formatter.date(from: body.startTime) else {
      throw Abort(.badRequest, reason: "Invalid start time format")
    }
    let endTime = body.endTime.flatMap { formatter.date(from: $0) }

    // Get max sort_order for this day
    let maxOrder = try await ScheduleSlot.query(on: req.db)
      .filter(\.$conference.$id == body.conferenceId)
      .filter(\.$day == body.day)
      .sort(\.$sortOrder, .descending)
      .first()?.sortOrder ?? -1

    let slot = ScheduleSlot(
      conferenceID: body.conferenceId,
      proposalID: body.proposalId,
      day: body.day,
      startTime: startTime,
      endTime: endTime,
      slotType: slotType,
      customTitle: body.customTitle,
      customTitleJa: body.customTitleJa,
      place: body.place,
      placeJa: body.placeJa,
      sortOrder: maxOrder + 1
    )

    try await slot.save(on: req.db)

    // Reload with relations
    let reloadQuery = ScheduleSlot.query(on: req.db)
      .filter(\.$id == slot.id!)
      .with(\.$proposal) { proposal in
        proposal.with(\.$speaker)
        proposal.with(\.$conference)
      }
    guard let saved = try await reloadQuery.first() else {
      throw Abort(.internalServerError, reason: "Failed to reload slot")
    }

    let dto = try ScheduleSlotDTO(slot: saved)
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    let data = try encoder.encode(dto)

    var headers = HTTPHeaders()
    headers.contentType = .json
    return Response(status: .created, headers: headers, body: .init(data: data))
  }

  @Sendable
  func updateSlot(req: Request) async throws -> Response {
    guard let user = try? await getAuthenticatedUser(req: req), user.role == .admin else {
      throw Abort(.unauthorized, reason: "Admin access required")
    }

    guard let slotIDString = req.parameters.get("slotID"),
      let slotID = UUID(uuidString: slotIDString)
    else {
      throw Abort(.badRequest, reason: "Invalid slot ID")
    }

    guard let slot = try await ScheduleSlot.find(slotID, on: req.db) else {
      throw Abort(.notFound, reason: "Slot not found")
    }

    struct UpdateSlotRequest: Content {
      var proposalId: UUID?
      var day: Int?
      var startTime: String?
      var endTime: String?
      var slotType: String?
      var customTitle: String?
      var customTitleJa: String?
      var place: String?
      var placeJa: String?
    }

    let body = try req.content.decode(UpdateSlotRequest.self)
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime]

    if let slotTypeStr = body.slotType, let slotType = SlotType(rawValue: slotTypeStr) {
      slot.slotType = slotType
    }
    if let day = body.day {
      slot.day = day
    }
    if let startTimeStr = body.startTime, let startTime = formatter.date(from: startTimeStr) {
      slot.startTime = startTime
    }
    if let endTimeStr = body.endTime {
      slot.endTime = formatter.date(from: endTimeStr)
    }
    if let proposalId = body.proposalId {
      slot.$proposal.id = proposalId
    }
    slot.customTitle = body.customTitle ?? slot.customTitle
    slot.customTitleJa = body.customTitleJa ?? slot.customTitleJa
    slot.place = body.place ?? slot.place
    slot.placeJa = body.placeJa ?? slot.placeJa

    try await slot.save(on: req.db)

    return Response(status: .ok)
  }

  @Sendable
  func deleteSlot(req: Request) async throws -> Response {
    guard let user = try? await getAuthenticatedUser(req: req), user.role == .admin else {
      throw Abort(.unauthorized, reason: "Admin access required")
    }

    guard let slotIDString = req.parameters.get("slotID"),
      let slotID = UUID(uuidString: slotIDString)
    else {
      throw Abort(.badRequest, reason: "Invalid slot ID")
    }

    guard let slot = try await ScheduleSlot.find(slotID, on: req.db) else {
      throw Abort(.notFound, reason: "Slot not found")
    }

    try await slot.delete(on: req.db)

    return Response(status: .noContent)
  }

  @Sendable
  func reorderSlots(req: Request) async throws -> Response {
    guard let user = try? await getAuthenticatedUser(req: req), user.role == .admin else {
      throw Abort(.unauthorized, reason: "Admin access required")
    }

    struct ReorderItem: Content {
      var id: UUID
      var sortOrder: Int
    }

    let items = try req.content.decode([ReorderItem].self)

    for item in items {
      if let slot = try await ScheduleSlot.find(item.id, on: req.db) {
        slot.sortOrder = item.sortOrder
        try await slot.save(on: req.db)
      }
    }

    return Response(status: .ok)
  }

  // MARK: - Timetable JSON Export

  @Sendable
  func exportTimetableJSON(req: Request) async throws -> Response {
    guard let user = try? await getAuthenticatedUser(req: req), user.role == .admin else {
      throw Abort(.unauthorized, reason: "Admin access required")
    }

    guard let dayString = req.parameters.get("day"), let day = Int(dayString) else {
      throw Abort(.badRequest, reason: "Invalid day parameter")
    }

    guard
      let conference = try await Conference.query(on: req.db)
        .sort(\.$year, .descending)
        .first(),
      let conferenceID = conference.id
    else {
      throw Abort(.notFound, reason: "No conference found")
    }

    let json = try await buildTimetableJSON(
      req: req, conference: conference, conferenceID: conferenceID, day: day)

    return try encodeTimetableResponse(json, filename: "2026-day\(day).json")
  }

  @Sendable
  func exportAllTimetableJSON(req: Request) async throws -> Response {
    guard let user = try? await getAuthenticatedUser(req: req), user.role == .admin else {
      throw Abort(.unauthorized, reason: "Admin access required")
    }

    guard
      let conference = try await Conference.query(on: req.db)
        .sort(\.$year, .descending)
        .first(),
      let conferenceID = conference.id
    else {
      throw Abort(.notFound, reason: "No conference found")
    }

    let days = computeConferenceDays(conference: conference)
    var allDays: [TimetableExportConference] = []

    for dayInfo in days {
      let json = try await buildTimetableJSON(
        req: req, conference: conference, conferenceID: conferenceID, day: dayInfo.dayNumber)
      allDays.append(json)
    }

    return try encodeTimetableResponse(allDays, filename: "timetable-all.json")
  }

  private func encodeTimetableResponse<T: Encodable>(_ value: T, filename: String) throws
    -> Response
  {
    let encoder = JSONEncoder()
    encoder.keyEncodingStrategy = .convertToSnakeCase
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    nonisolated(unsafe) let jstFormatter = ISO8601DateFormatter()
    jstFormatter.formatOptions = [.withInternetDateTime]
    jstFormatter.timeZone = TimeZone(identifier: "Asia/Tokyo")!
    encoder.dateEncodingStrategy = .custom { date, encoder in
      var container = encoder.singleValueContainer()
      try container.encode(jstFormatter.string(from: date))
    }

    let data = try encoder.encode(value)

    var headers = HTTPHeaders()
    headers.contentType = .json
    headers.add(name: .contentDisposition, value: "attachment; filename=\"\(filename)\"")
    return Response(status: .ok, headers: headers, body: .init(data: data))
  }

  private func buildTimetableJSON(
    req: Request, conference: Conference, conferenceID: UUID, day: Int
  ) async throws -> TimetableExportConference {
    let slots = try await ScheduleSlot.query(on: req.db)
      .filter(\.$conference.$id == conferenceID)
      .filter(\.$day == day)
      .with(\.$proposal) { proposal in
        proposal.with(\.$speaker)
        proposal.with(\.$conference)
      }
      .sort(\.$sortOrder)
      .all()

    // Group slots by start_time
    var schedulesByTime: [(time: Date, slots: [ScheduleSlot])] = []
    var currentTime: Date?
    var currentSlots: [ScheduleSlot] = []

    for slot in slots {
      if slot.startTime != currentTime {
        if let time = currentTime, !currentSlots.isEmpty {
          schedulesByTime.append((time: time, slots: currentSlots))
        }
        currentTime = slot.startTime
        currentSlots = [slot]
      } else {
        currentSlots.append(slot)
      }
    }
    if let time = currentTime, !currentSlots.isEmpty {
      schedulesByTime.append((time: time, slots: currentSlots))
    }

    let schedules = schedulesByTime.map { group -> TimetableExportSchedule in
      let sessions = group.slots.map { slot -> TimetableExportSession in
        if let proposal = slot.proposal {
          return TimetableExportSession(
            title: proposal.title,
            titleJa: nil,
            summary: String(proposal.abstract.prefix(200)),
            summaryJa: nil,
            speakers: [
              TimetableExportSpeaker(
                name: proposal.speakerName,
                imageName:
                  proposal.speakerName.lowercased().replacingOccurrences(of: " ", with: "_"),
                bio: proposal.bio,
                bioJa: nil,
                links: []
              )
            ],
            place: slot.place,
            placeJa: slot.placeJa,
            description: proposal.abstract,
            descriptionJa: nil
          )
        } else {
          return TimetableExportSession(
            title: slot.customTitle ?? slot.slotType.displayName,
            titleJa: slot.customTitleJa,
            summary: nil,
            summaryJa: nil,
            speakers: nil,
            place: slot.place,
            placeJa: slot.placeJa,
            description: slot.descriptionText,
            descriptionJa: slot.descriptionTextJa
          )
        }
      }
      return TimetableExportSchedule(time: group.time, sessions: sessions)
    }

    let dayDate: Date
    if let startDate = conference.startDate {
      dayDate = Calendar.current.date(byAdding: .day, value: day - 1, to: startDate) ?? startDate
    } else {
      dayDate = Date()
    }

    let dayLabels = ["Workshop", "Day 1", "Day 2"]
    let dayLabel = day <= dayLabels.count ? dayLabels[day - 1] : "Day \(day)"

    return TimetableExportConference(
      id: day,
      title: dayLabel,
      titleJa: nil,
      date: dayDate,
      schedules: schedules
    )
  }

  // MARK: - Timetable Helper Types

  struct DayInfo: Sendable {
    let dayNumber: Int
    let label: String
    let date: Date?
  }

  func computeConferenceDays(conference: Conference) -> [DayInfo] {
    guard let startDate = conference.startDate, let endDate = conference.endDate else {
      return [DayInfo(dayNumber: 1, label: "Day 1", date: nil)]
    }

    var days: [DayInfo] = []
    let calendar = Calendar.current
    var current = startDate
    var dayNum = 1
    let dayLabels = ["Workshop", "Day 1", "Day 2"]

    while current <= endDate {
      let label = dayNum <= dayLabels.count ? dayLabels[dayNum - 1] : "Day \(dayNum)"
      days.append(DayInfo(dayNumber: dayNum, label: label, date: current))
      dayNum += 1
      guard let next = calendar.date(byAdding: .day, value: 1, to: current) else { break }
      current = next
    }

    return days
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
