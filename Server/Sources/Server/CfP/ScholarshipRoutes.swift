import Fluent
import Foundation
import JWT
import SharedModels
import Vapor
import VaporElementary

/// Routes for Scholarship SSR pages
struct ScholarshipRoutes: RouteCollection {
  func boot(routes: RoutesBuilder) throws {
    // Apply CSRF protection to all scholarship routes
    let csrf = routes.grouped(CSRFMiddleware())

    // English routes (default) - under /scholarship
    let scholarship = csrf.grouped("scholarship")
    scholarship.get(use: scholarshipInfoPage)
    scholarship.get("apply", use: scholarshipApplyPage)
    scholarship.post("apply", use: handleScholarshipApply)
    scholarship.get("my-application", use: myScholarshipApplicationPage)
    scholarship.post("my-application", "withdraw", use: handleWithdrawApplication)

    // API (no language prefix needed)
    scholarship.get("api", "travel-cost", use: travelCostEstimate)

    // Japanese routes
    let ja = csrf.grouped("ja", "scholarship")
    ja.get(use: scholarshipInfoPageJa)
    ja.get("apply", use: scholarshipApplyPageJa)
    ja.post("apply", use: handleScholarshipApplyJa)
    ja.get("my-application", use: myScholarshipApplicationPageJa)
    ja.post("my-application", "withdraw", use: handleWithdrawApplicationJa)

    // Organizer routes
    let organizer = csrf.grouped("organizer")
    organizer.get("scholarships", use: organizerScholarshipsPage)
    organizer.get("scholarships", "export", use: organizerExportScholarshipsCSV)
    organizer.get("scholarships", ":applicationID", use: organizerScholarshipDetailPage)
    organizer.post("scholarships", ":applicationID", "approve", use: handleApproveScholarship)
    organizer.post("scholarships", ":applicationID", "reject", use: handleRejectScholarship)
    organizer.post("scholarships", ":applicationID", "revert", use: handleRevertScholarshipStatus)
    organizer.get("scholarship-budget", use: organizerScholarshipBudgetPage)
    organizer.post("scholarship-budget", use: handleUpdateScholarshipBudget)
  }

  // MARK: - English Page Handlers

  @Sendable
  func scholarshipInfoPage(req: Request) async throws -> HTMLResponse {
    try await renderScholarshipInfoPage(req: req, language: .en)
  }

  @Sendable
  func scholarshipApplyPage(req: Request) async throws -> HTMLResponse {
    try await renderScholarshipApplyPage(req: req, language: .en)
  }

  @Sendable
  func handleScholarshipApply(req: Request) async throws -> Response {
    try await processScholarshipApply(req: req, language: .en)
  }

  @Sendable
  func myScholarshipApplicationPage(req: Request) async throws -> HTMLResponse {
    try await renderMyScholarshipApplicationPage(req: req, language: .en)
  }

  @Sendable
  func handleWithdrawApplication(req: Request) async throws -> Response {
    try await processWithdrawApplication(req: req, language: .en)
  }

  // MARK: - Japanese Page Handlers

  @Sendable
  func scholarshipInfoPageJa(req: Request) async throws -> HTMLResponse {
    try await renderScholarshipInfoPage(req: req, language: .ja)
  }

  @Sendable
  func scholarshipApplyPageJa(req: Request) async throws -> HTMLResponse {
    try await renderScholarshipApplyPage(req: req, language: .ja)
  }

  @Sendable
  func handleScholarshipApplyJa(req: Request) async throws -> Response {
    try await processScholarshipApply(req: req, language: .ja)
  }

  @Sendable
  func myScholarshipApplicationPageJa(req: Request) async throws -> HTMLResponse {
    try await renderMyScholarshipApplicationPage(req: req, language: .ja)
  }

  @Sendable
  func handleWithdrawApplicationJa(req: Request) async throws -> Response {
    try await processWithdrawApplication(req: req, language: .ja)
  }

  // MARK: - API

  @Sendable
  func travelCostEstimate(req: Request) async throws -> Response {
    guard let from = req.query[String.self, at: "from"] else {
      throw Abort(.badRequest, reason: "Missing 'from' query parameter")
    }

    if let estimate = TravelCostCalculator.estimate(from: from) {
      let encoder = JSONEncoder()
      let data = try encoder.encode(estimate)
      var headers = HTTPHeaders()
      headers.contentType = .json
      return Response(status: .ok, headers: headers, body: .init(data: data))
    } else {
      return Response(status: .notFound)
    }
  }

  // MARK: - Shared Render Methods

  private func renderScholarshipInfoPage(req: Request, language: CfPLanguage) async throws
    -> HTMLResponse
  {
    let user = try? await req.authenticatedUser()

    // Get budget info
    let conference = try await Conference.query(on: req.db)
      .filter(\.$isOpen == true)
      .sort(\.$year, .descending)
      .first()

    var remainingBudget: Int?
    var budgetSet = false

    if let conference, let conferenceID = conference.id {
      let budget = try await ScholarshipBudget.query(on: req.db)
        .filter(\.$conference.$id == conferenceID)
        .first()

      if let budget {
        budgetSet = true
        let approvedTotal = try await ScholarshipApplication.query(on: req.db)
          .filter(\.$conference.$id == conferenceID)
          .filter(\.$status == .approved)
          .all()
          .compactMap { $0.approvedAmount }
          .reduce(0, +)
        remainingBudget = budget.totalBudget - approvedTotal
      }
    }

    // Check for existing application
    var hasExistingApplication = false
    if let user, let conference, let conferenceID = conference.id {
      let existing = try await ScholarshipApplication.query(on: req.db)
        .filter(\.$conference.$id == conferenceID)
        .filter(\.$applicant.$id == user.id)
        .first()
      hasExistingApplication = existing != nil
    }

    return HTMLResponse {
      CfPLayout(
        title: language == .ja ? "学生スカラシップ" : "Student Scholarship",
        user: user,
        language: language,
        currentPath: "/scholarship"
      ) {
        ScholarshipInfoPageView(
          user: user,
          language: language,
          remainingBudget: remainingBudget,
          budgetSet: budgetSet,
          hasExistingApplication: hasExistingApplication
        )
      }
    }
  }

  private func renderScholarshipApplyPage(req: Request, language: CfPLanguage) async throws
    -> HTMLResponse
  {
    let user = try? await req.authenticatedUser()
    let success = req.query[String.self, at: "success"] == "true"

    let conference = try await Conference.query(on: req.db)
      .filter(\.$isOpen == true)
      .sort(\.$year, .descending)
      .first()

    let csrfToken = req.csrfToken

    // Get budget info for remaining budget display
    var remaining: Int?
    if let conference, let conferenceID = conference.id {
      let budget = try await ScholarshipBudget.query(on: req.db)
        .filter(\.$conference.$id == conferenceID)
        .first()

      if let budget {
        let approvedTotal = try await ScholarshipApplication.query(on: req.db)
          .filter(\.$conference.$id == conferenceID)
          .filter(\.$status == .approved)
          .all()
          .compactMap { $0.approvedAmount }
          .reduce(0, +)
        remaining = budget.totalBudget - approvedTotal
      }
    }

    return HTMLResponse {
      CfPLayout(
        title: language == .ja ? "スカラシップ申請" : "Scholarship Application",
        user: user,
        language: language,
        currentPath: "/scholarship/apply"
      ) {
        ScholarshipApplyPageView(
          user: user,
          language: language,
          csrfToken: csrfToken,
          openConference: conference?.toPublicInfo(),
          remainingBudget: remaining,
          success: success,
          errorMessage: nil,
          isEducationalEmail: nil
        )
      }
    }
  }

  private func renderMyScholarshipApplicationPage(
    req: Request, language: CfPLanguage
  ) async throws -> HTMLResponse {
    let user = try? await req.authenticatedUser()
    var application: ScholarshipApplicationDTO?

    if let user {
      if let dbApplication = try await ScholarshipApplication.query(on: req.db)
        .filter(\.$applicant.$id == user.id)
        .with(\.$conference)
        .sort(\.$createdAt, .descending)
        .first()
      {
        application = try dbApplication.toDTO(
          applicantUsername: user.username,
          conference: dbApplication.conference
        )
      }
    }

    let csrfToken = req.csrfToken
    return HTMLResponse {
      CfPLayout(
        title: language == .ja ? "マイスカラシップ申請" : "My Scholarship Application",
        user: user,
        language: language,
        currentPath: "/scholarship/my-application"
      ) {
        MyScholarshipApplicationPageView(
          user: user,
          language: language,
          application: application,
          csrfToken: csrfToken
        )
      }
    }
  }

  // MARK: - Form Handlers

  private func processScholarshipApply(req: Request, language: CfPLanguage) async throws
    -> Response
  {
    guard let user = try? await req.authenticatedUser() else {
      return req.redirect(to: AuthURL.login(returnTo: language.path(for: "/scholarship/apply")))
    }

    // Decode form data
    struct ScholarshipFormData: Content {
      var name: String
      var email: String
      var school_and_faculty: String
      var current_year: String
      var portfolio: String?
      var github_account: String?
      var language_preference: String
      var existing_ticket_info: String?
      var support_type: String
      // Travel fields
      var origin_city: String?
      var transportation_methods: [String]?
      var estimated_round_trip_cost: String?
      // Accommodation fields
      var accommodation_type: String?
      var reservation_status: String?
      var accommodation_name: String?
      var accommodation_address: String?
      var check_in_date: String?
      var check_out_date: String?
      var estimated_accommodation_cost: String?
      // Financial
      var total_estimated_cost: String?
      var desired_support_amount: String?
      var self_payment_info: String?
      // Agreements
      var agreed_travel_regulations: String?
      var agreed_application_confirmation: String?
      var agreed_privacy: String?
      var agreed_code_of_conduct: String?
      // Additional
      var additional_comments: String?

      // purposes[] requires a CodingKey since bracket syntax isn't a valid Swift identifier
      var purposes: [String]?
      enum CodingKeys: String, CodingKey {
        case name, email, portfolio, purposes = "purposes[]"
        case school_and_faculty, current_year, github_account
        case language_preference, existing_ticket_info, support_type
        case origin_city, transportation_methods, estimated_round_trip_cost
        case accommodation_type, reservation_status, accommodation_name
        case accommodation_address, check_in_date, check_out_date
        case estimated_accommodation_cost, total_estimated_cost
        case desired_support_amount, self_payment_info
        case agreed_travel_regulations, agreed_application_confirmation
        case agreed_privacy, agreed_code_of_conduct, additional_comments
      }
    }

    let formData: ScholarshipFormData
    do {
      formData = try req.content.decode(ScholarshipFormData.self)
    } catch {
      return try await renderScholarshipApplyPageWithError(
        req: req,
        user: user,
        error: language == .ja ? "フォームデータが無効です" : "Invalid form data",
        language: language
      )
    }

    // Validate required fields
    guard !formData.name.isEmpty else {
      return try await renderScholarshipApplyPageWithError(
        req: req, user: user,
        error: language == .ja ? "氏名は必須です" : "Full name is required",
        language: language)
    }
    guard !formData.email.isEmpty else {
      return try await renderScholarshipApplyPageWithError(
        req: req, user: user,
        error: language == .ja ? "メールアドレスは必須です" : "Email address is required",
        language: language)
    }
    guard !formData.school_and_faculty.isEmpty else {
      return try await renderScholarshipApplyPageWithError(
        req: req, user: user,
        error: language == .ja ? "学校名・学部は必須です" : "School and faculty is required",
        language: language)
    }
    guard !formData.current_year.isEmpty else {
      return try await renderScholarshipApplyPageWithError(
        req: req, user: user,
        error: language == .ja ? "学年は必須です" : "Current year is required",
        language: language)
    }
    guard !formData.language_preference.isEmpty else {
      return try await renderScholarshipApplyPageWithError(
        req: req, user: user,
        error: language == .ja ? "言語の選択は必須です" : "Language preference is required",
        language: language)
    }

    // Validate support type
    guard let supportType = ScholarshipSupportType(rawValue: formData.support_type) else {
      return try await renderScholarshipApplyPageWithError(
        req: req, user: user,
        error: language == .ja ? "サポート種別を選択してください" : "Please select a support type",
        language: language)
    }

    // Conditional validation for travel/accommodation fields when support_type is "ticket_and_travel"
    var travelDetails: TravelDetails?
    var accommodationDetails: AccommodationDetails?

    if supportType == .ticketAndTravel {
      // Travel validation
      guard let originCity = formData.origin_city, !originCity.isEmpty else {
        return try await renderScholarshipApplyPageWithError(
          req: req, user: user,
          error: language == .ja ? "出発地は必須です" : "Origin city is required",
          language: language)
      }

      let transportMethods =
        formData.transportation_methods?.compactMap { TransportMethod(rawValue: $0) } ?? []

      guard let costStr = formData.estimated_round_trip_cost,
        let roundTripCost = Int(costStr), roundTripCost > 0
      else {
        return try await renderScholarshipApplyPageWithError(
          req: req, user: user,
          error: language == .ja ? "往復交通費の見積もりは必須です" : "Estimated round-trip cost is required",
          language: language)
      }

      travelDetails = TravelDetails(
        originCity: originCity,
        transportationMethods: transportMethods,
        estimatedRoundTripCost: roundTripCost
      )

      // Accommodation validation
      if let accTypeStr = formData.accommodation_type, !accTypeStr.isEmpty,
        let accType = AccommodationType(rawValue: accTypeStr)
      {
        let resStatus =
          formData.reservation_status.flatMap { ReservationStatus(rawValue: $0) } ?? .notYet

        guard let accCostStr = formData.estimated_accommodation_cost,
          let accCost = Int(accCostStr), accCost > 0
        else {
          return try await renderScholarshipApplyPageWithError(
            req: req, user: user,
            error: language == .ja ? "宿泊費の見積もりは必須です"
              : "Estimated accommodation cost is required",
            language: language)
        }

        accommodationDetails = AccommodationDetails(
          accommodationType: accType,
          reservationStatus: resStatus,
          accommodationName: formData.accommodation_name?.isEmpty == true
            ? nil : formData.accommodation_name,
          accommodationAddress: formData.accommodation_address?.isEmpty == true
            ? nil : formData.accommodation_address,
          checkInDate: formData.check_in_date?.isEmpty == true ? nil : formData.check_in_date,
          checkOutDate: formData.check_out_date?.isEmpty == true ? nil : formData.check_out_date,
          estimatedCost: accCost
        )
      }
    }

    // Check all 4 agreement checkboxes
    guard formData.agreed_travel_regulations == "on" || formData.agreed_travel_regulations == "true"
    else {
      return try await renderScholarshipApplyPageWithError(
        req: req, user: user,
        error: language == .ja ? "旅費規程への同意は必須です"
          : "You must agree to the travel regulations",
        language: language)
    }
    guard formData.agreed_application_confirmation == "on"
      || formData.agreed_application_confirmation == "true"
    else {
      return try await renderScholarshipApplyPageWithError(
        req: req, user: user,
        error: language == .ja ? "申請内容の確認への同意は必須です"
          : "You must confirm the application details",
        language: language)
    }
    guard formData.agreed_privacy == "on" || formData.agreed_privacy == "true" else {
      return try await renderScholarshipApplyPageWithError(
        req: req, user: user,
        error: language == .ja ? "プライバシーポリシーへの同意は必須です"
          : "You must agree to the privacy policy",
        language: language)
    }
    guard formData.agreed_code_of_conduct == "on" || formData.agreed_code_of_conduct == "true" else {
      return try await renderScholarshipApplyPageWithError(
        req: req, user: user,
        error: language == .ja ? "行動規範への同意は必須です"
          : "You must agree to the Code of Conduct",
        language: language)
    }

    // Find current open conference
    guard
      let conference = try await Conference.query(on: req.db)
        .filter(\.$isOpen == true)
        .sort(\.$year, .descending)
        .first()
    else {
      return try await renderScholarshipApplyPageWithError(
        req: req, user: user,
        error: language == .ja
          ? "現在スカラシップの募集は行っていません。"
          : "Scholarship applications are not currently open.",
        language: language)
    }

    guard let conferenceID = conference.id else {
      return try await renderScholarshipApplyPageWithError(
        req: req, user: user,
        error: language == .ja ? "カンファレンスの設定エラー" : "Conference configuration error",
        language: language)
    }

    // Check for duplicate applications (conference_id + applicant_id unique)
    let existing = try await ScholarshipApplication.query(on: req.db)
      .filter(\.$conference.$id == conferenceID)
      .filter(\.$applicant.$id == user.id)
      .first()

    if existing != nil {
      return try await renderScholarshipApplyPageWithError(
        req: req, user: user,
        error: language == .ja
          ? "このカンファレンスには既にスカラシップ申請済みです。"
          : "You have already submitted a scholarship application for this conference.",
        language: language)
    }

    // Financial fields
    let totalEstimatedCost = formData.total_estimated_cost.flatMap { Int($0) }
    let desiredSupportAmount = formData.desired_support_amount.flatMap { Int($0) }

    // Create ScholarshipApplication model and save
    let application = ScholarshipApplication(
      conferenceID: conferenceID,
      applicantID: user.id,
      email: formData.email,
      name: formData.name,
      schoolAndFaculty: formData.school_and_faculty,
      currentYear: formData.current_year,
      portfolio: formData.portfolio?.isEmpty == true ? nil : formData.portfolio,
      githubAccount: formData.github_account?.isEmpty == true ? nil : formData.github_account,
      purposes: PurposeList(formData.purposes ?? []),
      languagePreference: formData.language_preference,
      existingTicketInfo: formData.existing_ticket_info?.isEmpty == true
        ? nil : formData.existing_ticket_info,
      supportType: supportType,
      travelDetails: travelDetails,
      accommodationDetails: accommodationDetails,
      totalEstimatedCost: totalEstimatedCost,
      desiredSupportAmount: desiredSupportAmount,
      selfPaymentInfo: formData.self_payment_info?.isEmpty == true
        ? nil : formData.self_payment_info,
      agreedTravelRegulations: true,
      agreedApplicationConfirmation: true,
      agreedPrivacy: true,
      agreedCodeOfConduct: true,
      additionalComments: formData.additional_comments?.isEmpty == true
        ? nil : formData.additional_comments
    )

    try await application.save(on: req.db)

    // Send Slack notification
    await SlackNotifier.notifyNewScholarshipApplication(
      name: formData.name,
      school: formData.school_and_faculty,
      supportType: formData.support_type,
      client: req.client,
      logger: req.logger
    )

    // Redirect to success page
    return req.redirect(to: "\(language.path(for: "/scholarship/apply"))?success=true")
  }

  private func renderScholarshipApplyPageWithError(
    req: Request,
    user: UserDTO?,
    error: String,
    language: CfPLanguage
  ) async throws -> Response {
    let conference = try await Conference.query(on: req.db)
      .filter(\.$isOpen == true)
      .sort(\.$year, .descending)
      .first()
    let csrfToken = req.csrfToken

    // Get budget info for remaining budget display
    var remaining: Int?
    if let conference, let conferenceID = conference.id {
      let budget = try await ScholarshipBudget.query(on: req.db)
        .filter(\.$conference.$id == conferenceID)
        .first()

      if let budget {
        let approvedTotal = try await ScholarshipApplication.query(on: req.db)
          .filter(\.$conference.$id == conferenceID)
          .filter(\.$status == .approved)
          .all()
          .compactMap { $0.approvedAmount }
          .reduce(0, +)
        remaining = budget.totalBudget - approvedTotal
      }
    }

    let html = HTMLResponse {
      CfPLayout(
        title: language == .ja ? "スカラシップ申請" : "Scholarship Application",
        user: user,
        language: language,
        currentPath: "/scholarship/apply"
      ) {
        ScholarshipApplyPageView(
          user: user,
          language: language,
          csrfToken: csrfToken,
          openConference: conference?.toPublicInfo(),
          remainingBudget: remaining,
          success: false,
          errorMessage: error,
          isEducationalEmail: nil
        )
      }
    }
    return try await html.encodeResponse(for: req)
  }

  // MARK: - Withdraw Application

  private func processWithdrawApplication(req: Request, language: CfPLanguage) async throws
    -> Response
  {
    guard let user = try? await req.authenticatedUser() else {
      return req.redirect(
        to: AuthURL.login(returnTo: language.path(for: "/scholarship/my-application")))
    }

    // Find the user's application
    guard
      let application = try await ScholarshipApplication.query(on: req.db)
        .filter(\.$applicant.$id == user.id)
        .sort(\.$createdAt, .descending)
        .first()
    else {
      throw Abort(
        .notFound,
        reason: language == .ja ? "申請が見つかりません" : "Application not found")
    }

    // Set status to withdrawn
    application.status = .withdrawn
    try await application.save(on: req.db)

    // Redirect with success message
    return req.redirect(
      to: "\(language.path(for: "/scholarship/my-application"))?withdrawn=true")
  }

  // MARK: - Organizer Pages

  @Sendable
  func organizerScholarshipsPage(req: Request) async throws -> HTMLResponse {
    let user = try? await req.authenticatedUser()
    var applications: [ScholarshipApplicationDTO] = []
    let conferencePath = req.query[String.self, at: "conference"]

    if let user, user.role == .admin {
      let query = ScholarshipApplication.query(on: req.db)
        .with(\.$applicant)
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

      let dbApplications = try await query.all()
      applications = try dbApplications.map {
        try $0.toDTO(
          applicantUsername: $0.applicant.username,
          conference: $0.conference
        )
      }
    }

    // Get budget info
    var budgetInfo: (total: Int, approved: Int, remaining: Int)?
    if let user, user.role == .admin {
      let openConference = try await Conference.query(on: req.db)
        .filter(\.$isOpen == true)
        .sort(\.$year, .descending)
        .first()

      if let openConference, let conferenceID = openConference.id {
        let budget = try await ScholarshipBudget.query(on: req.db)
          .filter(\.$conference.$id == conferenceID)
          .first()

        if let budget {
          let approvedTotal = try await ScholarshipApplication.query(on: req.db)
            .filter(\.$conference.$id == conferenceID)
            .filter(\.$status == .approved)
            .all()
            .compactMap { $0.approvedAmount }
            .reduce(0, +)
          budgetInfo = (
            total: budget.totalBudget,
            approved: approvedTotal,
            remaining: budget.totalBudget - approvedTotal
          )
        }
      }
    }

    return HTMLResponse {
      CfPLayout(title: "Organizer - Scholarships", user: user) {
        OrganizerScholarshipsPageView(
          user: user,
          language: .en,
          applications: applications,
          totalBudget: budgetInfo?.total,
          approvedTotal: budgetInfo?.approved ?? 0,
          remainingBudget: budgetInfo?.remaining
        )
      }
    }
  }

  @Sendable
  func organizerScholarshipDetailPage(req: Request) async throws -> HTMLResponse {
    let user = try? await req.authenticatedUser()
    var application: ScholarshipApplicationDTO?

    if let user, user.role == .admin {
      if let applicationIDString = req.parameters.get("applicationID"),
        let applicationID = UUID(uuidString: applicationIDString)
      {
        if let dbApplication = try await ScholarshipApplication.query(on: req.db)
          .filter(\.$id == applicationID)
          .with(\.$applicant)
          .with(\.$conference)
          .first()
        {
          application = try dbApplication.toDTO(
            applicantUsername: dbApplication.applicant.username,
            conference: dbApplication.conference
          )
        }
      }
    }

    guard let application else {
      throw Abort(.notFound, reason: "Application not found")
    }

    let csrfToken = req.csrfToken
    return HTMLResponse {
      CfPLayout(
        title: application.name,
        user: user
      ) {
        OrganizerScholarshipDetailPageView(
          user: user,
          language: .en,
          application: application,
          csrfToken: csrfToken
        )
      }
    }
  }

  @Sendable
  func organizerExportScholarshipsCSV(req: Request) async throws -> Response {
    guard let user = try? await req.authenticatedUser(), user.role == .admin
    else {
      throw Abort(.unauthorized, reason: "Admin access required")
    }

    let conferencePath = req.query[String.self, at: "conference"]

    // Build query
    let query = ScholarshipApplication.query(on: req.db)
      .with(\.$applicant)
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

    let dbApplications = try await query.all()

    // Build CSV
    var csv =
      "ID,Name,Email,School,Year,Support Type,Status,Approved Amount,Origin City,Travel Cost,Accommodation Cost,Total Estimated Cost,Desired Support Amount,Language Preference,Portfolio,GitHub,Purposes,Conference,Submitted At,Organizer Notes\n"

    let dateFormatter = ISO8601DateFormatter()

    for app in dbApplications {
      var columns: [String] = []
      columns.append(app.id?.uuidString ?? "")
      columns.append(escapeCSV(app.name))
      columns.append(escapeCSV(app.email))
      columns.append(escapeCSV(app.schoolAndFaculty))
      columns.append(escapeCSV(app.currentYear))
      columns.append(app.supportType.rawValue)
      columns.append(app.status.rawValue)
      columns.append(app.approvedAmount.map { String($0) } ?? "")
      columns.append(escapeCSV(app.travelDetails?.originCity ?? ""))
      columns.append(app.travelDetails.map { String($0.estimatedRoundTripCost) } ?? "")
      columns.append(app.accommodationDetails.map { String($0.estimatedCost) } ?? "")
      columns.append(app.totalEstimatedCost.map { String($0) } ?? "")
      columns.append(app.desiredSupportAmount.map { String($0) } ?? "")
      columns.append(escapeCSV(app.languagePreference))
      columns.append(escapeCSV(app.portfolio ?? ""))
      columns.append(escapeCSV(app.githubAccount ?? ""))
      columns.append(escapeCSV(app.purposes.items.joined(separator: "; ")))
      columns.append(escapeCSV(app.conference.displayName))
      columns.append(app.createdAt.map { dateFormatter.string(from: $0) } ?? "")
      columns.append(escapeCSV(app.organizerNotes ?? ""))
      csv += columns.joined(separator: ",") + "\n"
    }

    var headers = HTTPHeaders()
    headers.add(name: .contentType, value: "text/csv; charset=utf-8")
    headers.add(
      name: .contentDisposition,
      value: "attachment; filename=\"scholarships-\(conferencePath ?? "all").csv\""
    )

    return Response(status: .ok, headers: headers, body: .init(string: csv))
  }

  // MARK: - Approve/Reject/Revert Scholarships

  @Sendable
  func handleApproveScholarship(req: Request) async throws -> Response {
    guard let user = try? await req.authenticatedUser(), user.role == .admin
    else {
      throw Abort(.unauthorized, reason: "Admin access required")
    }

    guard let applicationIDString = req.parameters.get("applicationID"),
      let applicationID = UUID(uuidString: applicationIDString)
    else {
      throw Abort(.badRequest, reason: "Invalid application ID")
    }

    guard let application = try await ScholarshipApplication.find(applicationID, on: req.db) else {
      throw Abort(.notFound, reason: "Application not found")
    }

    // Decode approved amount from form
    struct ApproveFormData: Content {
      var approved_amount: String
      var organizer_notes: String?
    }

    let formData: ApproveFormData
    do {
      formData = try req.content.decode(ApproveFormData.self)
    } catch {
      throw Abort(.badRequest, reason: "Approved amount is required")
    }

    let trimmedAmount = formData.approved_amount.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedAmount.isEmpty, let approvedAmount = Int(trimmedAmount) else {
      throw Abort(.badRequest, reason: "Approved amount must be a valid number")
    }

    application.status = .approved
    application.approvedAmount = approvedAmount
    if let notes = formData.organizer_notes, !notes.isEmpty {
      application.organizerNotes = notes
    }
    try await application.save(on: req.db)

    return req.redirect(to: "/organizer/scholarships/\(applicationID)")
  }

  @Sendable
  func handleRejectScholarship(req: Request) async throws -> Response {
    guard let user = try? await req.authenticatedUser(), user.role == .admin
    else {
      throw Abort(.unauthorized, reason: "Admin access required")
    }

    guard let applicationIDString = req.parameters.get("applicationID"),
      let applicationID = UUID(uuidString: applicationIDString)
    else {
      throw Abort(.badRequest, reason: "Invalid application ID")
    }

    guard let application = try await ScholarshipApplication.find(applicationID, on: req.db) else {
      throw Abort(.notFound, reason: "Application not found")
    }

    // Decode optional organizer notes from form
    struct RejectFormData: Content {
      var organizer_notes: String?
    }

    let formData = try? req.content.decode(RejectFormData.self)

    application.status = .rejected
    if let notes = formData?.organizer_notes, !notes.isEmpty {
      application.organizerNotes = notes
    }
    try await application.save(on: req.db)

    return req.redirect(to: "/organizer/scholarships/\(applicationID)")
  }

  @Sendable
  func handleRevertScholarshipStatus(req: Request) async throws -> Response {
    guard let user = try? await req.authenticatedUser(), user.role == .admin
    else {
      throw Abort(.unauthorized, reason: "Admin access required")
    }

    guard let applicationIDString = req.parameters.get("applicationID"),
      let applicationID = UUID(uuidString: applicationIDString)
    else {
      throw Abort(.badRequest, reason: "Invalid application ID")
    }

    guard let application = try await ScholarshipApplication.find(applicationID, on: req.db) else {
      throw Abort(.notFound, reason: "Application not found")
    }

    application.status = .submitted
    application.approvedAmount = nil
    try await application.save(on: req.db)

    return req.redirect(to: "/organizer/scholarships/\(applicationID)")
  }

  // MARK: - Budget Management

  @Sendable
  func organizerScholarshipBudgetPage(req: Request) async throws -> HTMLResponse {
    let user = try? await req.authenticatedUser()

    var budget: ScholarshipBudget?
    var approvedTotal = 0
    var applicationCount = 0

    if let user, user.role == .admin {
      let openConference = try await Conference.query(on: req.db)
        .filter(\.$isOpen == true)
        .sort(\.$year, .descending)
        .first()

      if let openConference, let conferenceID = openConference.id {
        budget = try await ScholarshipBudget.query(on: req.db)
          .filter(\.$conference.$id == conferenceID)
          .first()

        let applications = try await ScholarshipApplication.query(on: req.db)
          .filter(\.$conference.$id == conferenceID)
          .all()

        applicationCount = applications.count

        approvedTotal = applications
          .filter { $0.status == .approved }
          .compactMap { $0.approvedAmount }
          .reduce(0, +)
      }
    }

    let csrfToken = req.csrfToken
    return HTMLResponse {
      CfPLayout(title: "Organizer - Scholarship Budget", user: user) {
        OrganizerScholarshipBudgetPageView(
          user: user,
          language: .en,
          budget: budget?.totalBudget,
          notes: budget?.notes,
          approvedTotal: approvedTotal,
          applicationCount: applicationCount,
          csrfToken: csrfToken
        )
      }
    }
  }

  @Sendable
  func handleUpdateScholarshipBudget(req: Request) async throws -> Response {
    guard let user = try? await req.authenticatedUser(), user.role == .admin
    else {
      throw Abort(.unauthorized, reason: "Admin access required")
    }

    struct BudgetFormData: Content {
      var total_budget: String
      var budget_notes: String?
    }

    let formData: BudgetFormData
    do {
      formData = try req.content.decode(BudgetFormData.self)
    } catch {
      return req.redirect(
        to: "/organizer/scholarship-budget?error=Invalid+form+data")
    }

    guard let totalBudget = Int(formData.total_budget), totalBudget >= 0 else {
      return req.redirect(
        to: "/organizer/scholarship-budget?error=Invalid+budget+amount")
    }

    // Use the current open conference
    guard let openConference = try await Conference.query(on: req.db)
      .filter(\.$isOpen == true)
      .sort(\.$year, .descending)
      .first(),
      let conferenceID = openConference.id
    else {
      return req.redirect(
        to: "/organizer/scholarship-budget?error=No+open+conference")
    }

    // Find or create budget for this conference
    let existing = try await ScholarshipBudget.query(on: req.db)
      .filter(\.$conference.$id == conferenceID)
      .first()

    if let existing {
      existing.totalBudget = totalBudget
      existing.notes = formData.budget_notes?.isEmpty == true ? nil : formData.budget_notes
      try await existing.save(on: req.db)
    } else {
      let budget = ScholarshipBudget(
        conferenceID: conferenceID,
        totalBudget: totalBudget,
        notes: formData.budget_notes?.isEmpty == true ? nil : formData.budget_notes
      )
      try await budget.save(on: req.db)
    }

    return req.redirect(to: "/organizer/scholarship-budget?success=true")
  }

  // MARK: - Helpers

  private func escapeCSV(_ value: String) -> String {
    // Prevent CSV formula injection: prefix leading formula characters with
    // a single-quote so spreadsheet applications treat the cell as text.
    var sanitized = value
    if let first = sanitized.first, "=+-@".contains(first) {
      sanitized = "'" + sanitized
    }

    let needsQuoting =
      sanitized.contains(",") || sanitized.contains("\"") || sanitized.contains("\n")
      || sanitized.contains("\r")
    if needsQuoting {
      let escaped = sanitized.replacingOccurrences(of: "\"", with: "\"\"")
      return "\"\(escaped)\""
    }
    return sanitized
  }
}
