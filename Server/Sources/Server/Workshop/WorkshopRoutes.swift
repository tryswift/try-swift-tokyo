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

    // Public routes - Japanese
    let ja = csrf.grouped("ja")
    ja.get("workshops", use: workshopListPageJa)
    ja.get("workshops", "apply", use: workshopApplyPageJa)
    ja.post("workshops", "verify", use: handleVerifyTicketJa)
    ja.post("workshops", "apply", use: handleApplyJa)
    ja.get("workshops", "status", use: workshopStatusPageJa)
    ja.post("workshops", "status", use: handleCheckStatusJa)

    // Organizer routes (reuse existing organizer group pattern)
    let organizer = csrf.grouped("organizer")
    organizer.get("workshops", use: organizerWorkshopsPage)
    organizer.post("workshops", ":registrationID", "capacity", use: handleSetCapacity)
    organizer.post(
      "workshops", ":registrationID", "create-luma-event", use: handleCreateLumaEvent)
    organizer.post(
      "workshops", ":registrationID", "luma-event", use: handleSetLumaEvent)
    organizer.get("workshops", "applications", use: organizerApplicationsPage)
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
    let speakerName: String
    let abstract: String
    let capacity: Int
    let applicationCount: Int
    let lumaEventID: String?
  }

  /// Fetch accepted workshops with registration info
  private func fetchWorkshops(on db: Database) async throws -> [FetchedWorkshop] {
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

      let appCount = try await WorkshopApplication.query(on: db)
        .filter(\.$firstChoice.$id == regID)
        .count()

      results.append(
        FetchedWorkshop(
          registrationID: regID,
          proposalTitle: proposal.title,
          speakerName: proposal.speakerName,
          abstract: proposal.abstract,
          capacity: registration.capacity,
          applicationCount: appCount,
          lumaEventID: registration.lumaEventID
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

  // MARK: - Shared Rendering

  private func renderWorkshopListPage(req: Request, language: CfPLanguage) async throws
    -> HTMLResponse
  {
    let user = try? await req.authenticatedUser()
    let workshops = try await fetchWorkshops(on: req.db)
    let hasLotteryRun =
      try await WorkshopApplication.query(on: req.db)
      .filter(\.$status != .pending)
      .count() > 0

    let items = workshops.map {
      WorkshopListPageView.WorkshopItem(
        id: $0.registrationID,
        title: $0.proposalTitle,
        speakerName: $0.speakerName,
        abstract: $0.abstract,
        capacity: $0.capacity,
        applicationCount: $0.applicationCount
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
          applicationOpen: !hasLotteryRun
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
    if (try await WorkshopApplication.query(on: req.db)
      .filter(\.$email == email)
      .first()) != nil
    {
      let html = try await renderWorkshopApplyPage(
        req: req, language: language,
        errorMessage: language == .ja
          ? "このメールアドレスは既に申し込み済みです。"
          : "This email has already been used to apply."
      )
      return try await html.encodeResponse(for: req)
    }

    // Verify Luma ticket (skip if Luma API is not configured)
    let guestName: String
    if Environment.get("LUMA_API_KEY") != nil {
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
      req.logger.info("LUMA_API_KEY not configured, skipping ticket verification")
      guestName = ""
    }

    // Generate verify token
    let payload = WorkshopVerifyPayload(email: email, name: guestName)
    let token = try await req.jwt.sign(payload)

    // Show workshop selection form
    let user = try? await req.authenticatedUser()
    let workshops = try await fetchWorkshops(on: req.db)
    let workshopOptions = workshops.map {
      WorkshopOption(
        id: $0.registrationID, title: $0.proposalTitle, speakerName: $0.speakerName)
    }

    let html = HTMLResponse {
      CfPLayout(
        title: language == .ja ? "ワークショップ選択" : "Select Workshops",
        user: user,
        language: language,
        currentPath: "/workshops/apply"
      ) {
        WorkshopSelectPageView(
          workshops: workshopOptions,
          email: email,
          applicantName: guestName,
          verifyToken: token,
          language: language,
          csrfToken: csrfToken(from: req),
          errorMessage: nil
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
      let second_choice_id: UUID?
      let third_choice_id: UUID?
    }

    let form = try req.content.decode(ApplyForm.self)

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

    // Check for duplicate application
    if (try await WorkshopApplication.query(on: req.db)
      .filter(\.$email == email)
      .first()) != nil
    {
      let html = try await renderWorkshopApplyPage(
        req: req, language: language,
        errorMessage: language == .ja
          ? "このメールアドレスは既に申し込み済みです。"
          : "This email has already been used to apply."
      )
      return try await html.encodeResponse(for: req)
    }

    // Validate choices are different
    let choices = [form.first_choice_id, form.second_choice_id, form.third_choice_id].compactMap {
      $0
    }
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

    // Save application
    let application = WorkshopApplication(
      email: email,
      applicantName: form.applicant_name.trimmingCharacters(in: .whitespacesAndNewlines),
      firstChoiceID: form.first_choice_id,
      secondChoiceID: form.second_choice_id,
      thirdChoiceID: form.third_choice_id
    )
    try await application.save(on: req.db)

    // Get workshop titles for confirmation
    let firstTitle = try await workshopTitle(for: form.first_choice_id, on: req.db)
    let secondTitle =
      if let id = form.second_choice_id {
        try await workshopTitle(for: id, on: req.db)
      } else {
        nil as String?
      }
    let thirdTitle =
      if let id = form.third_choice_id {
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
          language: language
        )
      }
    }
    return try await html.encodeResponse(for: req)
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

    let info = WorkshopStatusPageView.ApplicationInfo(
      email: application.email,
      applicantName: application.applicantName,
      status: application.status,
      firstChoice: firstTitle ?? "Unknown",
      secondChoice: secondTitle,
      thirdChoice: thirdTitle,
      assignedWorkshop: assignedTitle
    )

    let html = try await renderWorkshopStatusPage(
      req: req, language: language, application: info)
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
      for ws in workshops {
        workshopInfos.append(
          .init(
            registrationID: ws.registrationID,
            proposalTitle: ws.proposalTitle,
            speakerName: ws.speakerName,
            capacity: ws.capacity,
            applicationCount: ws.applicationCount,
            lumaEventID: ws.lumaEventID
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
    guard let user, user.role == .admin else {
      return HTMLResponse {
        CfPLayout(title: "Applications", user: user, language: .en) {
          OrganizerApplicationsPageView(
            applications: [], workshopFilter: nil, workshops: [])
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
          workshops: workshopList
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

    for winner in winners {
      guard let workshop = winner.assignedWorkshop,
        let lumaEventID = workshop.lumaEventID
      else { continue }

      do {
        let response = try await LumaClient.addGuestToEvent(
          eventID: lumaEventID,
          email: winner.email,
          name: winner.applicantName,
          client: req.client,
          logger: req.logger
        )
        winner.lumaGuestID = response.id
        try await winner.save(on: req.db)
        sent += 1
      } catch {
        req.logger.error("Failed to send ticket to \(winner.email): \(error)")
        errors += 1
      }
    }

    return req.redirect(
      to: "/organizer/workshops?success=Tickets sent: \(sent) success, \(errors) errors"
    )
  }
}
