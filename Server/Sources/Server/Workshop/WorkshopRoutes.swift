import Fluent
import JWT
import SharedModels
import Vapor
import VaporElementary

/// JWT payload for verified Luma ticket holders (short-lived)
struct WorkshopVerifyPayload: JWTPayload, Sendable {
  var subject: SubjectClaim  // email
  var name: String
  var expiration: ExpirationClaim

  init(email: String, name: String) {
    self.subject = SubjectClaim(value: email)
    self.name = name
    self.expiration = ExpirationClaim(value: Date().addingTimeInterval(1800))  // 30 minutes
  }

  func verify(using algorithm: some JWTAlgorithm) throws {
    try expiration.verifyNotExpired()
  }
}

/// Routes for workshop registration, lottery, and management
struct WorkshopRoutes: RouteCollection {
  func boot(routes: RoutesBuilder) throws {
    let csrf = routes.grouped(CSRFMiddleware())

    // Public routes - English
    csrf.get("workshops", use: workshopListPage)
    csrf.get("workshops", "apply", use: workshopApplyPage)
    csrf.post("workshops", "verify", use: handleVerifyTicket)
    csrf.post("workshops", "apply", use: handleApply)
    csrf.get("workshops", "status", use: workshopStatusPage)
    csrf.post("workshops", "status", use: handleCheckStatus)
    csrf.post("workshops", "delete", use: handleDeleteOwnApplication)

    // Public routes - Japanese
    let ja = csrf.grouped("ja")
    ja.get("workshops", use: workshopListPageJa)
    ja.get("workshops", "apply", use: workshopApplyPageJa)
    ja.post("workshops", "verify", use: handleVerifyTicketJa)
    ja.post("workshops", "apply", use: handleApplyJa)
    ja.get("workshops", "status", use: workshopStatusPageJa)
    ja.post("workshops", "status", use: handleCheckStatusJa)
    ja.post("workshops", "delete", use: handleDeleteOwnApplicationJa)

    // Organizer routes (reuse existing organizer group pattern)
    let organizer = csrf.grouped("organizer")
    organizer.get("workshops", use: organizerWorkshopsPage)
    organizer.post("workshops", ":registrationID", "capacity", use: handleSetCapacity)
    organizer.post(
      "workshops", ":registrationID", "create-luma-event", use: handleCreateLumaEvent)
    organizer.post(
      "workshops", ":registrationID", "luma-event", use: handleSetLumaEvent)
    organizer.get("workshops", "applications", use: organizerApplicationsPage)
    organizer.post(
      "workshops", "applications", ":applicationID", "delete", use: handleDeleteApplication)
    organizer.post("workshops", "lottery", use: handleRunLottery)
    organizer.get("workshops", "results", use: organizerResultsPage)
    organizer.post("workshops", "send-tickets", use: handleSendTickets)
  }

  // MARK: - Helpers

  private func csrfToken(from req: Request) -> String {
    req.cookies["csrf_token"]?.string ?? ""
  }

  /// Fetched workshop data used across multiple pages
  struct FetchedWorkshop: Sendable {
    let registrationID: UUID
    let proposalTitle: String
    let titleJA: String?
    let speakerName: String
    let abstract: String
    let abstractJA: String?
    let bio: String
    let bioJa: String?
    let iconURL: String?
    let githubUsername: String?
    let paperCallUsername: String?
    let workshopDetails: WorkshopDetails?
    let workshopDetailsJA: WorkshopDetailsJA?
    let coInstructors: [CoInstructor]?
    let capacity: Int
    let applicationCount: Int
    let lumaEventID: String?
    let workshopLanguage: WorkshopLanguage?
  }

  /// Compute remaining capacity per workshop: capacity minus won application count
  private func computeRemainingCapacity(on db: Database) async throws -> [UUID: Int] {
    let workshops = try await WorkshopRegistration.query(on: db).all()
    let wonApps = try await WorkshopApplication.query(on: db)
      .filter(\.$status == .won)
      .all()
    let wonCounts: [UUID?: Int] = Dictionary(grouping: wonApps) { $0.$assignedWorkshop.id }
      .mapValues(\.count)
    var result: [UUID: Int] = [:]
    for workshop in workshops {
      guard let id = workshop.id else { continue }
      result[id] = max(0, workshop.capacity - (wonCounts[id] ?? 0))
    }
    return result
  }

  /// Fetch accepted workshops with registration info
  private func fetchWorkshops(on db: Database, includeApplicationCount: Bool = true) async throws
    -> [FetchedWorkshop]
  {
    // Get accepted workshop proposals
    let proposals = try await Proposal.query(on: db)
      .filter(\.$talkDuration == .workshop)
      .filter(\.$status == .accepted)
      .with(\.$speaker)
      .sort(\.$title)
      .all()

    var results: [FetchedWorkshop] = []

    for proposal in proposals {
      guard let proposalID = proposal.id else { continue }

      // Find or create registration (with retry on unique constraint violation)
      let registration: WorkshopRegistration
      if let existing = try await WorkshopRegistration.query(on: db)
        .filter(\.$proposal.$id == proposalID)
        .first()
      {
        registration = existing
      } else {
        let newReg = WorkshopRegistration(proposalID: proposalID, capacity: 30)
        do {
          try await newReg.save(on: db)
          registration = newReg
        } catch {
          // Unique constraint violation from concurrent request — re-fetch
          guard
            let existing = try await WorkshopRegistration.query(on: db)
              .filter(\.$proposal.$id == proposalID)
              .first()
          else { throw error }
          registration = existing
        }
      }

      guard let regID = registration.id else { continue }

      let appCount =
        includeApplicationCount
        ? try await WorkshopApplication.query(on: db)
          .filter(\.$firstChoice.$id == regID)
          .count()
        : 0

      results.append(
        FetchedWorkshop(
          registrationID: regID,
          proposalTitle: proposal.title,
          titleJA: proposal.titleJA,
          speakerName: proposal.speakerName,
          abstract: proposal.abstract,
          abstractJA: proposal.abstractJA,
          bio: proposal.bio,
          bioJa: proposal.bioJa,
          iconURL: proposal.iconURL,
          githubUsername: proposal.githubUsername,
          paperCallUsername: proposal.paperCallUsername,
          workshopDetails: proposal.workshopDetails,
          workshopDetailsJA: proposal.workshopDetailsJA,
          coInstructors: proposal.coInstructors?.items,
          capacity: registration.capacity,
          applicationCount: appCount,
          lumaEventID: registration.lumaEventID,
          workshopLanguage: proposal.workshopDetails?.language
        ))
    }

    return results
  }

  // MARK: - English Handlers

  @Sendable
  func workshopListPage(req: Request) async throws -> HTMLResponse {
    try await renderWorkshopListPage(req: req, language: .en)
  }

  @Sendable
  func workshopApplyPage(req: Request) async throws -> HTMLResponse {
    try await renderWorkshopApplyPage(req: req, language: .en)
  }

  @Sendable
  func handleVerifyTicket(req: Request) async throws -> Response {
    try await processVerifyTicket(req: req, language: .en)
  }

  @Sendable
  func handleApply(req: Request) async throws -> Response {
    try await processApply(req: req, language: .en)
  }

  @Sendable
  func workshopStatusPage(req: Request) async throws -> HTMLResponse {
    try await renderWorkshopStatusPage(req: req, language: .en)
  }

  @Sendable
  func handleCheckStatus(req: Request) async throws -> Response {
    try await processCheckStatus(req: req, language: .en)
  }

  // MARK: - Japanese Handlers

  @Sendable
  func workshopListPageJa(req: Request) async throws -> HTMLResponse {
    try await renderWorkshopListPage(req: req, language: .ja)
  }

  @Sendable
  func workshopApplyPageJa(req: Request) async throws -> HTMLResponse {
    try await renderWorkshopApplyPage(req: req, language: .ja)
  }

  @Sendable
  func handleVerifyTicketJa(req: Request) async throws -> Response {
    try await processVerifyTicket(req: req, language: .ja)
  }

  @Sendable
  func handleApplyJa(req: Request) async throws -> Response {
    try await processApply(req: req, language: .ja)
  }

  @Sendable
  func workshopStatusPageJa(req: Request) async throws -> HTMLResponse {
    try await renderWorkshopStatusPage(req: req, language: .ja)
  }

  @Sendable
  func handleCheckStatusJa(req: Request) async throws -> Response {
    try await processCheckStatus(req: req, language: .ja)
  }

  @Sendable
  func handleDeleteOwnApplication(req: Request) async throws -> Response {
    try await processDeleteOwnApplication(req: req, language: .en)
  }

  @Sendable
  func handleDeleteOwnApplicationJa(req: Request) async throws -> Response {
    try await processDeleteOwnApplication(req: req, language: .ja)
  }

  // MARK: - Shared Rendering

  private func renderWorkshopListPage(req: Request, language: CfPLanguage) async throws
    -> HTMLResponse
  {
    let user = try? await req.authenticatedUser()
    let isOrganizer = user?.role == .admin
    let workshops = try await fetchWorkshops(on: req.db, includeApplicationCount: isOrganizer)
    let hasLotteryRun =
      try await WorkshopApplication.query(on: req.db)
      .filter(\.$status != .pending)
      .count() > 0

    let applicationOpen: Bool
    if !hasLotteryRun {
      applicationOpen = true
    } else {
      let remaining = try await computeRemainingCapacity(on: req.db)
      applicationOpen = remaining.values.contains { $0 > 0 }
    }

    let items = workshops.map {
      WorkshopListPageView.WorkshopItem(
        id: $0.registrationID,
        title: $0.proposalTitle,
        titleJA: $0.titleJA,
        speakerName: $0.speakerName,
        abstract: $0.abstract,
        abstractJA: $0.abstractJA,
        bio: $0.bio,
        bioJa: $0.bioJa,
        iconURL: $0.iconURL,
        githubUsername: $0.githubUsername,
        isPaperCallImport: $0.paperCallUsername != nil,
        workshopDetails: $0.workshopDetails,
        workshopDetailsJA: $0.workshopDetailsJA,
        coInstructors: $0.coInstructors,
        capacity: $0.capacity,
        applicationCount: $0.applicationCount,
        workshopLanguage: $0.workshopLanguage
      )
    }

    return HTMLResponse {
      CfPLayout(
        title: language == .ja ? "ワークショップ" : "Workshops",
        user: user,
        language: language,
        currentPath: "/workshops"
      ) {
        WorkshopListPageView(
          workshops: items,
          language: language,
          applicationOpen: applicationOpen,
          isOrganizer: isOrganizer
        )
      }
    }
  }

  private func renderWorkshopApplyPage(
    req: Request, language: CfPLanguage, errorMessage: String? = nil
  ) async throws -> HTMLResponse {
    let user = try? await req.authenticatedUser()
    return HTMLResponse {
      CfPLayout(
        title: language == .ja ? "チケット確認" : "Verify Ticket",
        user: user,
        language: language,
        currentPath: "/workshops/apply"
      ) {
        WorkshopVerifyPageView(
          language: language,
          csrfToken: csrfToken(from: req),
          errorMessage: errorMessage
        )
      }
    }
  }

  private func processVerifyTicket(req: Request, language: CfPLanguage) async throws -> Response {
    struct VerifyForm: Content {
      let email: String
    }

    let form = try req.content.decode(VerifyForm.self)
    let email = form.email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

    guard !email.isEmpty else {
      let html = try await renderWorkshopApplyPage(
        req: req, language: language,
        errorMessage: language == .ja ? "メールアドレスを入力してください。" : "Please enter an email address."
      )
      return try await html.encodeResponse(for: req)
    }

    // Check if already applied
    let existingApplication = try await WorkshopApplication.query(on: req.db)
      .filter(\.$email == email)
      .first()

    if let existingApplication, existingApplication.status == .won {
      let html = try await renderWorkshopApplyPage(
        req: req, language: language,
        errorMessage: language == .ja
          ? "既にワークショップに当選しています。"
          : "You have already been assigned a workshop."
      )
      return try await html.encodeResponse(for: req)
    }

    // Verify Luma ticket
    let guestName: String
    if Environment.get("SKIP_LUMA_VERIFICATION") == "true" {
      req.logger.debug("Luma ticket verification skipped (SKIP_LUMA_VERIFICATION=true)")
      guestName = ""
    } else if let lumaApiKey = Environment.get("LUMA_API_KEY"), !lumaApiKey.isEmpty {
      let guest: LumaGuest?
      do {
        guest = try await LumaClient.getGuest(
          email: email, client: req.client, logger: req.logger)
      } catch {
        req.logger.error("Luma API error during ticket verification: \(error)")
        let html = try await renderWorkshopApplyPage(
          req: req, language: language,
          errorMessage: language == .ja
            ? "チケット確認サービスに接続できませんでした。しばらくしてからもう一度お試しください。"
            : "Could not connect to the ticket verification service. Please try again later."
        )
        return try await html.encodeResponse(for: req)
      }

      guard let guest, guest.hasTicket else {
        let html = try await renderWorkshopApplyPage(
          req: req, language: language,
          errorMessage: language == .ja
            ? "このメールアドレスでtry! Swift Tokyo 2026のチケットが見つかりませんでした。"
            : "No try! Swift Tokyo 2026 ticket found for this email address."
        )
        return try await html.encodeResponse(for: req)
      }
      guestName = guest.displayName
    } else {
      let html = try await renderWorkshopApplyPage(
        req: req, language: language,
        errorMessage: language == .ja
          ? "チケット確認サービスが設定されていません。"
          : "Ticket verification service is not configured."
      )
      return try await html.encodeResponse(for: req)
    }

    // Generate verify token
    let payload = WorkshopVerifyPayload(email: email, name: guestName)
    let token = try await req.jwt.sign(payload)

    // Show workshop selection form
    let user = try? await req.authenticatedUser()
    let workshops = try await fetchWorkshops(on: req.db)

    // Check if lottery has run to determine post-lottery (FCFS) mode
    let hasLotteryRun =
      try await WorkshopApplication.query(on: req.db)
      .filter(\.$status != .pending)
      .count() > 0

    let workshopOptions: [WorkshopOption]
    if hasLotteryRun {
      // Post-lottery: only show workshops with remaining capacity
      let remaining = try await computeRemainingCapacity(on: req.db)
      workshopOptions = workshops
        .filter { (remaining[$0.registrationID] ?? 0) > 0 }
        .map {
          WorkshopOption(
            id: $0.registrationID, title: $0.proposalTitle, speakerName: $0.speakerName)
        }
    } else {
      workshopOptions = workshops.map {
        WorkshopOption(
          id: $0.registrationID, title: $0.proposalTitle, speakerName: $0.speakerName)
      }
    }

    let isEditMode = existingApplication != nil && existingApplication!.status == .pending
    let existingSelections: WorkshopSelectPageView.ExistingSelections?
    if let existingApplication, existingApplication.status == .pending {
      // Only prefill for pending applications (pre-lottery edit)
      existingSelections = WorkshopSelectPageView.ExistingSelections(
        firstChoiceID: existingApplication.$firstChoice.id,
        secondChoiceID: existingApplication.$secondChoice.id,
        thirdChoiceID: existingApplication.$thirdChoice.id
      )
    } else {
      existingSelections = nil
    }

    let applicantName =
      guestName.isEmpty && existingApplication != nil
      ? existingApplication!.applicantName : guestName

    let html = HTMLResponse {
      CfPLayout(
        title: language == .ja
          ? (isEditMode ? "ワークショップ申し込み変更" : "ワークショップ選択")
          : (isEditMode ? "Edit Workshop Application" : "Select Workshops"),
        user: user,
        language: language,
        currentPath: "/workshops/apply"
      ) {
        WorkshopSelectPageView(
          workshops: workshopOptions,
          email: email,
          applicantName: applicantName,
          verifyToken: token,
          language: language,
          csrfToken: csrfToken(from: req),
          errorMessage: nil,
          isEditMode: isEditMode,
          existingSelections: existingSelections,
          isPostLottery: hasLotteryRun
        )
      }
    }
    return try await html.encodeResponse(for: req)
  }

  private func processApply(req: Request, language: CfPLanguage) async throws -> Response {
    struct ApplyForm: Content {
      let email: String
      let applicant_name: String
      let verify_token: String
      let first_choice_id: UUID
      let second_choice_id: String?
      let third_choice_id: String?
    }

    let form = try req.content.decode(ApplyForm.self)

    // Parse optional choice IDs:
    // - nil or empty strings from the form become nil
    // - non-empty but invalid UUID strings cause a bad request
    let secondChoiceID: UUID?
    if let rawSecond = form.second_choice_id, !rawSecond.isEmpty {
      guard let parsed = UUID(uuidString: rawSecond) else {
        throw Abort(.badRequest, reason: "Invalid second_choice_id")
      }
      secondChoiceID = parsed
    } else {
      secondChoiceID = nil
    }

    let thirdChoiceID: UUID?
    if let rawThird = form.third_choice_id, !rawThird.isEmpty {
      guard let parsed = UUID(uuidString: rawThird) else {
        throw Abort(.badRequest, reason: "Invalid third_choice_id")
      }
      thirdChoiceID = parsed
    } else {
      thirdChoiceID = nil
    }

    // Verify the token
    let payload: WorkshopVerifyPayload
    do {
      payload = try await req.jwt.verify(form.verify_token, as: WorkshopVerifyPayload.self)
    } catch {
      let html = try await renderWorkshopApplyPage(
        req: req, language: language,
        errorMessage: language == .ja
          ? "セッションが期限切れです。もう一度メールアドレスを入力してください。"
          : "Session expired. Please enter your email again."
      )
      return try await html.encodeResponse(for: req)
    }

    let email = payload.subject.value

    // Check for existing application
    let existingApplication = try await WorkshopApplication.query(on: req.db)
      .filter(\.$email == email)
      .first()

    if let existingApplication, existingApplication.status == .won {
      let html = try await renderWorkshopApplyPage(
        req: req, language: language,
        errorMessage: language == .ja
          ? "既にワークショップに当選しています。"
          : "You have already been assigned a workshop."
      )
      return try await html.encodeResponse(for: req)
    }

    // Check if lottery has run to determine post-lottery (FCFS) mode
    let hasLotteryRun =
      try await WorkshopApplication.query(on: req.db)
      .filter(\.$status != .pending)
      .count() > 0

    if hasLotteryRun {
      // Post-lottery: first-come-first-served direct assignment
      let applicantName = form.applicant_name.trimmingCharacters(in: .whitespacesAndNewlines)
      let result = try await directAssign(
        email: email,
        applicantName: applicantName,
        workshopID: form.first_choice_id,
        existingApplication: existingApplication,
        on: req.db
      )

      switch result {
      case .assigned:
        let workshopTitle = try await workshopTitle(for: form.first_choice_id, on: req.db)
        let user = try? await req.authenticatedUser()
        let html = HTMLResponse {
          CfPLayout(
            title: language == .ja ? "申し込み完了" : "Application Complete",
            user: user,
            language: language,
            currentPath: "/workshops/apply"
          ) {
            WorkshopConfirmationPageView(
              email: email,
              applicantName: applicantName,
              firstChoice: workshopTitle ?? "Unknown",
              secondChoice: nil,
              thirdChoice: nil,
              language: language,
              isUpdate: existingApplication != nil,
              isPostLottery: true
            )
          }
        }
        return try await html.encodeResponse(for: req)

      case .full:
        let html = try await renderWorkshopApplyPage(
          req: req, language: language,
          errorMessage: language == .ja
            ? "申し訳ありませんが、選択したワークショップは満員になりました。別のワークショップをお試しください。"
            : "Sorry, the selected workshop is now full. Please try another workshop."
        )
        return try await html.encodeResponse(for: req)
      }
    }

    // Pre-lottery: standard lottery application flow

    // Validate choices are different
    let choices = [form.first_choice_id, secondChoiceID, thirdChoiceID].compactMap { $0 }
    let uniqueChoices = Set(choices)
    guard uniqueChoices.count == choices.count else {
      let html = try await renderWorkshopApplyPage(
        req: req, language: language,
        errorMessage: language == .ja
          ? "同じワークショップを複数回選択できません。"
          : "You cannot select the same workshop more than once."
      )
      return try await html.encodeResponse(for: req)
    }

    // Save or update application
    let isUpdate: Bool
    if let existingApplication {
      existingApplication.applicantName = form.applicant_name
        .trimmingCharacters(in: .whitespacesAndNewlines)
      existingApplication.$firstChoice.id = form.first_choice_id
      existingApplication.$secondChoice.id = secondChoiceID
      existingApplication.$thirdChoice.id = thirdChoiceID
      try await existingApplication.save(on: req.db)
      isUpdate = true
    } else {
      let application = WorkshopApplication(
        email: email,
        applicantName: form.applicant_name.trimmingCharacters(in: .whitespacesAndNewlines),
        firstChoiceID: form.first_choice_id,
        secondChoiceID: secondChoiceID,
        thirdChoiceID: thirdChoiceID
      )
      try await application.save(on: req.db)
      isUpdate = false
    }

    // Get workshop titles for confirmation
    let firstTitle = try await workshopTitle(for: form.first_choice_id, on: req.db)
    let secondTitle =
      if let id = secondChoiceID {
        try await workshopTitle(for: id, on: req.db)
      } else {
        nil as String?
      }
    let thirdTitle =
      if let id = thirdChoiceID {
        try await workshopTitle(for: id, on: req.db)
      } else {
        nil as String?
      }

    let user = try? await req.authenticatedUser()
    let html = HTMLResponse {
      CfPLayout(
        title: language == .ja ? "申し込み完了" : "Application Complete",
        user: user,
        language: language,
        currentPath: "/workshops/apply"
      ) {
        WorkshopConfirmationPageView(
          email: email,
          applicantName: form.applicant_name,
          firstChoice: firstTitle ?? "Unknown",
          secondChoice: secondTitle,
          thirdChoice: thirdTitle,
          language: language,
          isUpdate: isUpdate,
          isPostLottery: false
        )
      }
    }
    return try await html.encodeResponse(for: req)
  }

  /// Result of a direct (first-come-first-served) workshop assignment
  private enum DirectAssignResult {
    case assigned
    case full
  }

  /// Directly assign an applicant to a workshop (post-lottery, first-come-first-served).
  /// Uses a transaction to prevent race conditions on the last available slot.
  private func directAssign(
    email: String,
    applicantName: String,
    workshopID: UUID,
    existingApplication: WorkshopApplication?,
    on db: Database
  ) async throws -> DirectAssignResult {
    try await db.transaction { tx in
      // Count current won applications for this workshop within transaction
      let wonCount = try await WorkshopApplication.query(on: tx)
        .filter(\.$assignedWorkshop.$id == workshopID)
        .filter(\.$status == .won)
        .count()

      guard let workshop = try await WorkshopRegistration.find(workshopID, on: tx) else {
        return .full
      }

      guard wonCount < workshop.capacity else {
        return .full
      }

      // Assign directly
      if let existingApplication {
        existingApplication.applicantName = applicantName
        existingApplication.$firstChoice.id = workshopID
        existingApplication.$secondChoice.id = nil
        existingApplication.$thirdChoice.id = nil
        existingApplication.$assignedWorkshop.id = workshopID
        existingApplication.status = .won
        existingApplication.lumaGuestID = nil
        try await existingApplication.save(on: tx)
      } else {
        let application = WorkshopApplication(
          email: email,
          applicantName: applicantName,
          firstChoiceID: workshopID,
          status: .won
        )
        application.$assignedWorkshop.id = workshopID
        try await application.save(on: tx)
      }
      return .assigned
    }
  }

  private func workshopTitle(for registrationID: UUID, on db: Database) async throws -> String? {
    guard
      let reg = try await WorkshopRegistration.query(on: db)
        .filter(\.$id == registrationID)
        .with(\.$proposal)
        .first()
    else { return nil }
    return reg.proposal.title
  }

  /// Build a title cache for all workshop registrations to avoid N+1 queries
  private func buildTitleCache(on db: Database) async throws -> [UUID: String] {
    let registrations = try await WorkshopRegistration.query(on: db)
      .with(\.$proposal)
      .all()
    var cache: [UUID: String] = [:]
    for reg in registrations {
      guard let id = reg.id else { continue }
      cache[id] = reg.proposal.title
    }
    return cache
  }

  private func renderWorkshopStatusPage(
    req: Request, language: CfPLanguage, application: WorkshopStatusPageView.ApplicationInfo? = nil
  ) async throws -> HTMLResponse {
    let user = try? await req.authenticatedUser()
    return HTMLResponse {
      CfPLayout(
        title: language == .ja ? "申し込み状況" : "Application Status",
        user: user,
        language: language,
        currentPath: "/workshops/status"
      ) {
        WorkshopStatusPageView(
          language: language,
          csrfToken: csrfToken(from: req),
          application: application,
          showForm: true
        )
      }
    }
  }

  private func processCheckStatus(req: Request, language: CfPLanguage) async throws -> Response {
    struct StatusForm: Content {
      let email: String
    }

    let form = try req.content.decode(StatusForm.self)
    let email = form.email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

    guard
      let application = try await WorkshopApplication.query(on: req.db)
        .filter(\.$email == email)
        .with(\.$firstChoice)
        .with(\.$secondChoice)
        .with(\.$thirdChoice)
        .with(\.$assignedWorkshop)
        .first()
    else {
      let html = try await renderWorkshopStatusPage(req: req, language: language)
      return try await html.encodeResponse(for: req)
    }

    // Load proposal titles via separate queries
    let firstTitle = try await workshopTitle(for: application.$firstChoice.id, on: req.db)
    let secondTitle: String? =
      if let id = application.$secondChoice.id {
        try await workshopTitle(for: id, on: req.db)
      } else {
        nil
      }
    let thirdTitle: String? =
      if let id = application.$thirdChoice.id {
        try await workshopTitle(for: id, on: req.db)
      } else {
        nil
      }
    let assignedTitle: String? =
      if let id = application.$assignedWorkshop.id {
        try await workshopTitle(for: id, on: req.db)
      } else {
        nil
      }

    // Generate a short-lived delete token for pending applications
    let deleteToken: String?
    if application.status == .pending {
      let payload = WorkshopVerifyPayload(email: application.email, name: "")
      deleteToken = try await req.jwt.sign(payload)
    } else {
      deleteToken = nil
    }

    // Determine if user can reapply (lost + workshops with remaining capacity)
    let canReapply: Bool
    if application.status == .lost {
      let remaining = try await computeRemainingCapacity(on: req.db)
      canReapply = remaining.values.contains { $0 > 0 }
    } else {
      canReapply = false
    }

    let info = WorkshopStatusPageView.ApplicationInfo(
      email: application.email,
      applicantName: application.applicantName,
      status: application.status,
      firstChoice: firstTitle ?? "Unknown",
      secondChoice: secondTitle,
      thirdChoice: thirdTitle,
      assignedWorkshop: assignedTitle,
      canModify: application.status == .pending,
      canReapply: canReapply,
      deleteToken: deleteToken
    )

    let html = try await renderWorkshopStatusPage(
      req: req, language: language, application: info)
    return try await html.encodeResponse(for: req)
  }

  private func processDeleteOwnApplication(req: Request, language: CfPLanguage) async throws
    -> Response
  {
    struct DeleteForm: Content {
      let delete_token: String
    }

    let form = try req.content.decode(DeleteForm.self)

    // Verify JWT to authenticate the delete request
    let payload: WorkshopVerifyPayload
    do {
      payload = try await req.jwt.verify(form.delete_token, as: WorkshopVerifyPayload.self)
    } catch {
      let html = try await renderWorkshopStatusPage(req: req, language: language)
      return try await html.encodeResponse(for: req)
    }

    let email = payload.subject.value

    // Atomic conditional delete: only delete pending applications
    try await WorkshopApplication.query(on: req.db)
      .filter(\.$email == email)
      .filter(\.$status == .pending)
      .delete()

    // Check if application still exists (status changed between page load and delete)
    if let current = try await WorkshopApplication.query(on: req.db)
      .filter(\.$email == email)
      .first()
    {
      let firstTitle = try await workshopTitle(for: current.$firstChoice.id, on: req.db)
      let secondTitle: String? =
        if let id = current.$secondChoice.id {
          try await workshopTitle(for: id, on: req.db)
        } else {
          nil
        }
      let thirdTitle: String? =
        if let id = current.$thirdChoice.id {
          try await workshopTitle(for: id, on: req.db)
        } else {
          nil
        }
      let assignedTitle: String? =
        if let id = current.$assignedWorkshop.id {
          try await workshopTitle(for: id, on: req.db)
        } else {
          nil
        }
      let canReapplyAfterDelete: Bool
      if current.status == .lost {
        let remaining = try await computeRemainingCapacity(on: req.db)
        canReapplyAfterDelete = remaining.values.contains { $0 > 0 }
      } else {
        canReapplyAfterDelete = false
      }

      let info = WorkshopStatusPageView.ApplicationInfo(
        email: current.email,
        applicantName: current.applicantName,
        status: current.status,
        firstChoice: firstTitle ?? "Unknown",
        secondChoice: secondTitle,
        thirdChoice: thirdTitle,
        assignedWorkshop: assignedTitle,
        canModify: false,
        canReapply: canReapplyAfterDelete,
        deleteToken: nil
      )
      let html = try await renderWorkshopStatusPage(
        req: req, language: language, application: info)
      return try await html.encodeResponse(for: req)
    }

    let user = try? await req.authenticatedUser()
    let html = HTMLResponse {
      CfPLayout(
        title: language == .ja ? "申し込み取り消し完了" : "Application Deleted",
        user: user,
        language: language,
        currentPath: "/workshops/status"
      ) {
        WorkshopDeleteConfirmationView(language: language)
      }
    }
    return try await html.encodeResponse(for: req)
  }

  // MARK: - Organizer Handlers

  @Sendable
  func organizerWorkshopsPage(req: Request) async throws -> HTMLResponse {
    let user = try? await req.authenticatedUser()
    let successMessage = req.query[String.self, at: "success"]

    var workshopInfos: [OrganizerWorkshopsPageView.WorkshopInfo] = []
    if let user, user.role == .admin {
      let workshops = try await fetchWorkshops(on: req.db)

      // Fetch all winners in a single query to avoid N+1
      let allWinners = try await WorkshopApplication.query(on: req.db)
        .filter(\.$status == .won)
        .all()
      let winnersByWorkshop = Dictionary(grouping: allWinners) { $0.$assignedWorkshop.id }

      for ws in workshops {
        let emails = (winnersByWorkshop[ws.registrationID] ?? []).map(\.email)
        workshopInfos.append(
          .init(
            registrationID: ws.registrationID,
            proposalTitle: ws.proposalTitle,
            speakerName: ws.speakerName,
            capacity: ws.capacity,
            applicationCount: ws.applicationCount,
            lumaEventID: ws.lumaEventID,
            winnerEmails: emails
          ))
      }
    }

    return HTMLResponse {
      CfPLayout(
        title: "Workshop Management",
        user: user,
        language: .en,
        currentPath: "/organizer/workshops"
      ) {
        OrganizerWorkshopsPageView(
          user: user,
          workshops: workshopInfos,
          csrfToken: csrfToken(from: req),
          successMessage: successMessage
        )
      }
    }
  }

  @Sendable
  func handleSetCapacity(req: Request) async throws -> Response {
    let user = try? await req.authenticatedUser()
    guard let user, user.role == .admin else {
      throw Abort(.forbidden)
    }

    guard let registrationID = req.parameters.get("registrationID", as: UUID.self) else {
      throw Abort(.badRequest)
    }

    struct CapacityForm: Content {
      let capacity: Int
    }
    let form = try req.content.decode(CapacityForm.self)

    guard form.capacity >= 1, form.capacity <= 1000 else {
      throw Abort(.badRequest, reason: "Capacity must be between 1 and 1000")
    }

    guard let registration = try await WorkshopRegistration.find(registrationID, on: req.db) else {
      throw Abort(.notFound)
    }

    registration.capacity = form.capacity
    try await registration.save(on: req.db)

    return req.redirect(to: "/organizer/workshops?success=Capacity updated")
  }

  @Sendable
  func handleCreateLumaEvent(req: Request) async throws -> Response {
    let user = try? await req.authenticatedUser()
    guard let user, user.role == .admin else {
      throw Abort(.forbidden)
    }

    guard let registrationID = req.parameters.get("registrationID", as: UUID.self) else {
      throw Abort(.badRequest)
    }

    guard
      let registration = try await WorkshopRegistration.query(on: req.db)
        .filter(\.$id == registrationID)
        .with(\.$proposal)
        .first()
    else {
      throw Abort(.notFound)
    }

    guard registration.lumaEventID == nil else {
      return req.redirect(
        to:
          "/organizer/workshops?success=Luma event already exists: \(registration.lumaEventID ?? "")"
      )
    }

    let proposal = registration.proposal
    let eventResponse = try await LumaClient.createEvent(
      name: "try! Swift Tokyo 2026 Workshop: \(proposal.title)",
      descriptionMd: proposal.abstract,
      startAt: Environment.get("WORKSHOP_DEFAULT_START_AT") ?? "2026-04-13T09:00:00+09:00",
      endAt: Environment.get("WORKSHOP_DEFAULT_END_AT") ?? "2026-04-13T17:00:00+09:00",
      client: req.client,
      logger: req.logger
    )

    registration.lumaEventID = eventResponse.id
    try await registration.save(on: req.db)

    return req.redirect(to: "/organizer/workshops?success=Luma event created: \(eventResponse.id)")
  }

  @Sendable
  func handleSetLumaEvent(req: Request) async throws -> Response {
    let user = try? await req.authenticatedUser()
    guard let user, user.role == .admin else {
      throw Abort(.forbidden)
    }

    guard let registrationID = req.parameters.get("registrationID", as: UUID.self) else {
      throw Abort(.badRequest)
    }

    struct LumaEventForm: Content {
      let luma_event_id: String
    }
    let form = try req.content.decode(LumaEventForm.self)

    guard let registration = try await WorkshopRegistration.find(registrationID, on: req.db) else {
      throw Abort(.notFound)
    }

    let trimmed = form.luma_event_id.trimmingCharacters(in: .whitespacesAndNewlines)

    if !trimmed.isEmpty {
      let maxLength = 128
      let allowedCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
      guard trimmed.count <= maxLength,
        trimmed.unicodeScalars.allSatisfy({ allowedCharacters.contains($0) })
      else {
        throw Abort(
          .badRequest,
          reason:
            "Invalid Luma event ID. Use only letters, numbers, '-' and '_', maximum \(maxLength) characters."
        )
      }
    }

    registration.lumaEventID = trimmed.isEmpty ? nil : trimmed
    try await registration.save(on: req.db)

    return req.redirect(to: "/organizer/workshops?success=Luma event ID updated")
  }

  @Sendable
  func organizerApplicationsPage(req: Request) async throws -> HTMLResponse {
    let user = try? await req.authenticatedUser()
    let successMessage = req.query[String.self, at: "success"]
    guard let user, user.role == .admin else {
      return HTMLResponse {
        CfPLayout(title: "Applications", user: user, language: .en) {
          OrganizerApplicationsPageView(
            applications: [], workshopFilter: nil, workshops: [],
            csrfToken: "", successMessage: nil)
        }
      }
    }

    let workshopFilter = req.query[String.self, at: "workshop"]

    let query = WorkshopApplication.query(on: req.db)
      .with(\.$firstChoice)
      .with(\.$secondChoice)
      .with(\.$thirdChoice)
      .with(\.$assignedWorkshop)
      .sort(\.$createdAt, .descending)

    let applications = try await query.all()

    let dateFormatter = DateFormatter()
    dateFormatter.dateStyle = .medium
    dateFormatter.timeStyle = .short

    let titleCache = try await buildTitleCache(on: req.db)

    var rows: [OrganizerApplicationsPageView.ApplicationRow] = []
    for app in applications {
      guard let id = app.id else { continue }

      let firstTitle = titleCache[app.$firstChoice.id]
      let secondTitle = app.$secondChoice.id.flatMap { titleCache[$0] }
      let thirdTitle = app.$thirdChoice.id.flatMap { titleCache[$0] }
      let assignedTitle = app.$assignedWorkshop.id.flatMap { titleCache[$0] }

      rows.append(
        .init(
          id: id,
          email: app.email,
          applicantName: app.applicantName,
          firstChoice: firstTitle ?? "Unknown",
          secondChoice: secondTitle,
          thirdChoice: thirdTitle,
          status: app.status,
          assignedWorkshop: assignedTitle,
          createdAt: app.createdAt.map { dateFormatter.string(from: $0) } ?? "-"
        ))
    }

    let filteredRows: [OrganizerApplicationsPageView.ApplicationRow]
    if let workshopFilter, let filterUUID = UUID(uuidString: workshopFilter) {
      let filteredIDs = Set(
        applications.filter { app in
          app.$firstChoice.id == filterUUID
            || app.$secondChoice.id == filterUUID
            || app.$thirdChoice.id == filterUUID
        }.compactMap { $0.id }
      )
      filteredRows = rows.filter { filteredIDs.contains($0.id) }
    } else {
      filteredRows = rows
    }

    let workshops = try await fetchWorkshops(on: req.db)
    let workshopList = workshops.map {
      WorkshopFilterOption(id: $0.registrationID, title: $0.proposalTitle)
    }

    return HTMLResponse {
      CfPLayout(
        title: "Workshop Applications",
        user: user,
        language: .en,
        currentPath: "/organizer/workshops/applications"
      ) {
        OrganizerApplicationsPageView(
          applications: filteredRows,
          workshopFilter: workshopFilter,
          workshops: workshopList,
          csrfToken: csrfToken(from: req),
          successMessage: successMessage
        )
      }
    }
  }

  @Sendable
  func handleRunLottery(req: Request) async throws -> Response {
    let user = try? await req.authenticatedUser()
    guard let user, user.role == .admin else {
      throw Abort(.forbidden)
    }

    let result = try await LotteryService.runLottery(on: req.db)

    return req.redirect(
      to:
        "/organizer/workshops?success=Lottery complete: \(result.assigned) assigned, \(result.unassigned) unassigned out of \(result.totalApplications) total"
    )
  }

  @Sendable
  func organizerResultsPage(req: Request) async throws -> HTMLResponse {
    let user = try? await req.authenticatedUser()
    guard let user, user.role == .admin else {
      throw Abort(.forbidden)
    }

    let workshops = try await WorkshopRegistration.query(on: req.db)
      .with(\.$proposal)
      .all()

    let lotteryRun =
      try await WorkshopApplication.query(on: req.db)
      .filter(\.$status != .pending)
      .count() > 0

    var results: [OrganizerResultsPageView.WorkshopResult] = []
    for workshop in workshops {
      guard let workshopID = workshop.id else { continue }

      let winners = try await WorkshopApplication.query(on: req.db)
        .filter(\.$assignedWorkshop.$id == workshopID)
        .filter(\.$status == .won)
        .all()

      let ticketsSent = winners.allSatisfy { $0.lumaGuestID != nil }

      results.append(
        .init(
          workshopTitle: workshop.proposal.title,
          capacity: workshop.capacity,
          winners: winners.map { LotteryWinner(name: $0.applicantName, email: $0.email) },
          lumaEventID: workshop.lumaEventID,
          ticketsSent: !winners.isEmpty && ticketsSent
        ))
    }

    return HTMLResponse {
      CfPLayout(
        title: "Lottery Results",
        user: user,
        language: .en,
        currentPath: "/organizer/workshops/results"
      ) {
        OrganizerResultsPageView(results: results, lotteryRun: lotteryRun)
      }
    }
  }

  @Sendable
  func handleDeleteApplication(req: Request) async throws -> Response {
    let user = try? await req.authenticatedUser()
    guard let user, user.role == .admin else {
      throw Abort(.forbidden)
    }

    guard let applicationIDString = req.parameters.get("applicationID"),
      let applicationID = UUID(uuidString: applicationIDString)
    else {
      throw Abort(.badRequest, reason: "Invalid application ID")
    }

    guard let application = try await WorkshopApplication.find(applicationID, on: req.db) else {
      throw Abort(.notFound, reason: "Application not found")
    }

    try await application.delete(on: req.db)

    return req.redirect(to: "/organizer/workshops/applications?success=Application+deleted")
  }

  @Sendable
  func handleSendTickets(req: Request) async throws -> Response {
    let user = try? await req.authenticatedUser()
    guard let user, user.role == .admin else {
      throw Abort(.forbidden)
    }

    // Get all winners who haven't received tickets yet
    let winners = try await WorkshopApplication.query(on: req.db)
      .filter(\.$status == .won)
      .filter(\.$lumaGuestID == nil)
      .with(\.$assignedWorkshop)
      .all()

    var sent = 0
    var errors = 0
    var skipped = 0

    // Group winners by Luma event ID for batch processing
    var winnersByEvent: [String: [WorkshopApplication]] = [:]
    for winner in winners {
      guard let workshop = winner.assignedWorkshop,
        let lumaEventID = workshop.lumaEventID
      else { continue }
      winnersByEvent[lumaEventID, default: []].append(winner)
    }

    for (lumaEventID, eventWinners) in winnersByEvent {
      // 1. Fetch existing guests to skip duplicates and sync DB
      var existingEmails: [String: String] = [:]  // email -> guestID
      do {
        let guests = try await LumaClient.getGuests(
          eventID: lumaEventID,
          client: req.client,
          logger: req.logger
        )
        for guest in guests {
          if let email = guest.user_email?.lowercased(), let id = guest.id {
            existingEmails[email] = id
          }
        }
      } catch {
        req.logger.error(
          "Failed to fetch existing guests for event \(lumaEventID): \(error)")
      }

      // 2. Separate already-invited from new guests
      var newWinners: [WorkshopApplication] = []
      for winner in eventWinners {
        if let guestID = existingEmails[winner.email.lowercased()] {
          winner.lumaGuestID = guestID
          try await winner.save(on: req.db)
          skipped += 1
        } else {
          newWinners.append(winner)
        }
      }

      guard !newWinners.isEmpty else { continue }

      // 3. Fetch Standard ticket type for this event
      let ticketTypeID: String
      do {
        let ticketTypes = try await LumaClient.getTicketTypes(
          eventID: lumaEventID,
          client: req.client,
          logger: req.logger
        )
        guard let standard = ticketTypes.first(where: { $0.name == "Standard" }) else {
          req.logger.error("No 'Standard' ticket type found for event \(lumaEventID)")
          errors += newWinners.count
          continue
        }
        ticketTypeID = standard.id
      } catch {
        req.logger.error(
          "Failed to fetch ticket types for event \(lumaEventID): \(error)")
        errors += newWinners.count
        continue
      }

      // 4. Batch add all new guests in a single API call
      let guestInputs = newWinners.map { LumaGuestInput(email: $0.email, name: $0.applicantName) }
      do {
        try await LumaClient.addGuestsToEvent(
          eventID: lumaEventID,
          guests: guestInputs,
          ticketTypeID: ticketTypeID,
          client: req.client,
          logger: req.logger
        )
      } catch {
        req.logger.error(
          "Failed to batch-add \(guestInputs.count) guests to event \(lumaEventID): \(error)")
        errors += newWinners.count
        continue
      }

      // 5. Re-fetch guest list to resolve guest IDs for DB
      do {
        let updatedGuests = try await LumaClient.getGuests(
          eventID: lumaEventID,
          client: req.client,
          logger: req.logger
        )
        var emailToID: [String: String] = [:]
        for guest in updatedGuests {
          if let email = guest.user_email?.lowercased(), let id = guest.id {
            emailToID[email] = id
          }
        }
        for winner in newWinners {
          if let guestID = emailToID[winner.email.lowercased()] {
            winner.lumaGuestID = guestID
            try await winner.save(on: req.db)
            sent += 1
          } else {
            req.logger.warning(
              "Guest \(winner.email) not found in Luma after batch add for event \(lumaEventID)")
            errors += 1
          }
        }
      } catch {
        req.logger.error(
          "Failed to re-fetch guests after batch add for event \(lumaEventID): \(error)")
        // Guests were added to Luma but we couldn't resolve IDs — count as sent
        sent += newWinners.count
      }
    }

    return req.redirect(
      to:
        "/organizer/workshops?success=Tickets sent: \(sent) success, \(skipped) skipped (already on Luma), \(errors) errors"
    )
  }
}
