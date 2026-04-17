import Fluent
import SharedModels
import Vapor

struct WorkshopListItemContent: Content {
  let registrationID: UUID
  let title: String
  let titleJA: String?
  let speakerName: String
  let abstract: String
  let abstractJA: String?
  let bio: String
  let bioJa: String?
  let iconURL: String?
  let githubUsername: String?
  let isPaperCallImport: Bool
  let workshopDetails: WorkshopDetails?
  let workshopDetailsJA: WorkshopDetailsJA?
  let coInstructors: [CoInstructor]?
  let capacity: Int
  let applicationCount: Int
  let remainingCapacity: Int
  let lumaEventID: String?
  let workshopLanguage: WorkshopLanguage?
}

struct WorkshopListResponseContent: Content {
  let hasLotteryRun: Bool
  let applicationOpen: Bool
  let workshops: [WorkshopListItemContent]
}

struct WorkshopOptionContent: Content {
  let id: UUID
  let title: String
  let speakerName: String
}

struct WorkshopExistingSelectionsContent: Content {
  let firstChoiceID: UUID
  let secondChoiceID: UUID?
  let thirdChoiceID: UUID?
}

struct WorkshopVerifyRequestContent: Content {
  let email: String
}

struct WorkshopVerifyResponseContent: Content {
  let email: String
  let applicantName: String
  let verifyToken: String
  let isEditMode: Bool
  let isPostLottery: Bool
  let workshops: [WorkshopOptionContent]
  let existingSelections: WorkshopExistingSelectionsContent?
}

struct WorkshopApplyRequestContent: Content {
  let applicantName: String
  let verifyToken: String
  let firstChoiceID: UUID
  let secondChoiceID: UUID?
  let thirdChoiceID: UUID?
}

struct WorkshopApplicationInfoContent: Content {
  let email: String
  let applicantName: String
  let status: String
  let firstChoice: String
  let secondChoice: String?
  let thirdChoice: String?
  let assignedWorkshop: String?
  let canModify: Bool
  let canReapply: Bool
  let deleteToken: String?
  let cancelToken: String?
  let createdAt: Date?
  let updatedAt: Date?
}

struct WorkshopApplyResponseContent: Content {
  let mode: String
  let isPostLottery: Bool
  let application: WorkshopApplicationInfoContent
}

struct WorkshopStatusRequestContent: Content {
  let email: String
}

struct WorkshopStatusResponseContent: Content {
  let found: Bool
  let application: WorkshopApplicationInfoContent?
}

struct WorkshopActionTokenRequestContent: Content {
  let token: String
}

struct WorkshopActionResponseContent: Content {
  let action: String
  let message: String
}

struct WorkshopController: RouteCollection {
  func boot(routes: RoutesBuilder) throws {
    let workshops = routes.grouped("workshops")
    workshops.get(use: list)
    workshops.post("verify", use: verifyTicket)
    workshops.post("apply", use: apply)
    workshops.post("status", use: status)
    workshops.post("delete", use: deleteOwnApplication)
    workshops.post("cancel", use: cancelApplication)
  }

  @Sendable
  func list(req: Request) async throws -> WorkshopListResponseContent {
    let user = try? await req.authenticatedUser()
    let includeApplicationCount = user?.role == .admin
    let workshops = try await WorkshopAPIService.fetchWorkshops(
      on: req.db,
      includeApplicationCount: includeApplicationCount
    )
    let hasLotteryRun = try await WorkshopAPIService.hasLotteryRun(on: req.db)
    let remaining = try await WorkshopAPIService.computeRemainingCapacity(on: req.db)

    let applicationOpen =
      if !hasLotteryRun {
        true
      } else {
        remaining.values.contains { $0 > 0 }
      }

    return WorkshopListResponseContent(
      hasLotteryRun: hasLotteryRun,
      applicationOpen: applicationOpen,
      workshops: workshops.map {
        WorkshopListItemContent(
          registrationID: $0.registrationID,
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
          remainingCapacity: remaining[$0.registrationID] ?? $0.capacity,
          lumaEventID: $0.lumaEventID,
          workshopLanguage: $0.workshopLanguage
        )
      }
    )
  }

  @Sendable
  func verifyTicket(req: Request) async throws -> WorkshopVerifyResponseContent {
    let form = try req.content.decode(WorkshopVerifyRequestContent.self)
    let email = form.email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

    guard !email.isEmpty else {
      throw Abort(.badRequest, reason: "Email is required")
    }

    let existingApplication = try await WorkshopApplication.query(on: req.db)
      .filter(\.$email == email)
      .first()

    if let existingApplication, existingApplication.status == .won {
      throw Abort(.conflict, reason: "You have already been assigned a workshop")
    }

    let guestName: String
    if Environment.get("SKIP_LUMA_VERIFICATION") == "true" {
      req.logger.debug("Luma ticket verification skipped (SKIP_LUMA_VERIFICATION=true)")
      guestName = ""
    } else if let lumaApiKey = Environment.get("LUMA_API_KEY"), !lumaApiKey.isEmpty {
      let guest: LumaGuest?
      do {
        guest = try await LumaClient.getGuest(
          email: email,
          client: req.client,
          logger: req.logger
        )
      } catch {
        req.logger.error("Luma API error during ticket verification: \(error)")
        throw Abort(
          .badGateway,
          reason: "Could not connect to the ticket verification service"
        )
      }

      guard let guest, guest.hasTicket else {
        throw Abort(.notFound, reason: "No try! Swift Tokyo 2026 ticket found for this email")
      }
      guestName = guest.displayName
    } else {
      throw Abort(.internalServerError, reason: "Ticket verification service is not configured")
    }

    let payload = WorkshopVerifyPayload(email: email, name: guestName)
    let token = try await req.jwt.sign(payload)
    let workshops = try await WorkshopAPIService.fetchWorkshops(on: req.db)
    let hasLotteryRun = try await WorkshopAPIService.hasLotteryRun(on: req.db)

    let availableWorkshops: [WorkshopOptionContent]
    if hasLotteryRun {
      let remaining = try await WorkshopAPIService.computeRemainingCapacity(on: req.db)
      availableWorkshops =
        workshops
        .filter { (remaining[$0.registrationID] ?? 0) > 0 }
        .map {
          WorkshopOptionContent(
            id: $0.registrationID,
            title: $0.proposalTitle,
            speakerName: $0.speakerName
          )
        }
    } else {
      availableWorkshops = workshops.map {
        WorkshopOptionContent(
          id: $0.registrationID,
          title: $0.proposalTitle,
          speakerName: $0.speakerName
        )
      }
    }

    let existingSelections: WorkshopExistingSelectionsContent? =
      if let existingApplication, existingApplication.status == .pending {
        WorkshopExistingSelectionsContent(
          firstChoiceID: existingApplication.$firstChoice.id,
          secondChoiceID: existingApplication.$secondChoice.id,
          thirdChoiceID: existingApplication.$thirdChoice.id
        )
      } else {
        nil
      }

    let applicantName: String =
      if guestName.isEmpty, let existingApplication {
        existingApplication.applicantName
      } else {
        guestName
      }

    return WorkshopVerifyResponseContent(
      email: email,
      applicantName: applicantName,
      verifyToken: token,
      isEditMode: existingApplication?.status == .pending,
      isPostLottery: hasLotteryRun,
      workshops: availableWorkshops,
      existingSelections: existingSelections
    )
  }

  @Sendable
  func apply(req: Request) async throws -> WorkshopApplyResponseContent {
    let form = try req.content.decode(WorkshopApplyRequestContent.self)

    let payload: WorkshopVerifyPayload
    do {
      payload = try await req.jwt.verify(form.verifyToken, as: WorkshopVerifyPayload.self)
    } catch {
      throw Abort(.unauthorized, reason: "Session expired. Please verify your email again.")
    }

    let email = payload.subject.value
    let applicantName = form.applicantName.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !applicantName.isEmpty else {
      throw Abort(.badRequest, reason: "Applicant name is required")
    }

    let existingApplication = try await WorkshopApplication.query(on: req.db)
      .filter(\.$email == email)
      .first()

    if let existingApplication, existingApplication.status == .won {
      throw Abort(.conflict, reason: "You have already been assigned a workshop")
    }

    let hasLotteryRun = try await WorkshopAPIService.hasLotteryRun(on: req.db)

    if hasLotteryRun {
      let result = try await WorkshopAPIService.directAssign(
        email: email,
        applicantName: applicantName,
        workshopID: form.firstChoiceID,
        existingApplication: existingApplication,
        on: req.db
      )

      switch result {
      case .assigned:
        let capturedEmail = email
        let capturedName = applicantName
        let capturedWorkshopID = form.firstChoiceID
        let db = req.db
        let client = req.client
        let logger = req.logger
        Task {
          await WorkshopAPIService.sendLumaInvitation(
            email: capturedEmail,
            applicantName: capturedName,
            workshopID: capturedWorkshopID,
            db: db,
            client: client,
            logger: logger
          )
        }

      case .full:
        throw Abort(.conflict, reason: "The selected workshop is full")
      }

      let info = try await applicationInfo(email: email, on: req)
      return WorkshopApplyResponseContent(
        mode: existingApplication == nil ? "assigned" : "reassigned",
        isPostLottery: true,
        application: info
      )
    }

    let choices = [form.firstChoiceID, form.secondChoiceID, form.thirdChoiceID].compactMap { $0 }
    guard Set(choices).count == choices.count else {
      throw Abort(.badRequest, reason: "You cannot select the same workshop more than once")
    }

    if let existingApplication {
      existingApplication.applicantName = applicantName
      existingApplication.$firstChoice.id = form.firstChoiceID
      existingApplication.$secondChoice.id = form.secondChoiceID
      existingApplication.$thirdChoice.id = form.thirdChoiceID
      try await existingApplication.save(on: req.db)
    } else {
      let application = WorkshopApplication(
        email: email,
        applicantName: applicantName,
        firstChoiceID: form.firstChoiceID,
        secondChoiceID: form.secondChoiceID,
        thirdChoiceID: form.thirdChoiceID
      )
      try await application.save(on: req.db)
    }

    let info = try await applicationInfo(email: email, on: req)
    return WorkshopApplyResponseContent(
      mode: existingApplication == nil ? "submitted" : "updated",
      isPostLottery: false,
      application: info
    )
  }

  @Sendable
  func status(req: Request) async throws -> WorkshopStatusResponseContent {
    let content = try req.content.decode(WorkshopStatusRequestContent.self)
    let email = content.email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    guard !email.isEmpty else {
      throw Abort(.badRequest, reason: "Email is required")
    }

    guard
      try await WorkshopApplication.query(on: req.db)
        .filter(\.$email == email)
        .first() != nil
    else {
      return WorkshopStatusResponseContent(found: false, application: nil)
    }

    return WorkshopStatusResponseContent(
      found: true,
      application: try await applicationInfo(email: email, on: req)
    )
  }

  @Sendable
  func deleteOwnApplication(req: Request) async throws -> WorkshopActionResponseContent {
    let content = try req.content.decode(WorkshopActionTokenRequestContent.self)
    let payload = try await verifyWorkshopActionToken(content.token, req: req)
    let email = payload.subject.value

    try await WorkshopApplication.query(on: req.db)
      .filter(\.$email == email)
      .filter(\.$status == .pending)
      .delete()

    if try await WorkshopApplication.query(on: req.db)
      .filter(\.$email == email)
      .first() != nil
    {
      throw Abort(.conflict, reason: "Application can no longer be deleted")
    }

    return WorkshopActionResponseContent(
      action: "delete",
      message: "Application deleted"
    )
  }

  @Sendable
  func cancelApplication(req: Request) async throws -> WorkshopActionResponseContent {
    let content = try req.content.decode(WorkshopActionTokenRequestContent.self)
    let payload = try await verifyWorkshopActionToken(content.token, req: req)
    let email = payload.subject.value

    guard
      let application = try await WorkshopApplication.query(on: req.db)
        .filter(\.$email == email)
        .filter(\.$status == .won)
        .first()
    else {
      throw Abort(.notFound, reason: "Winning application not found")
    }

    if let lumaGuestID = application.lumaGuestID,
      let assignedWorkshopID = application.$assignedWorkshop.id,
      let workshop = try await WorkshopRegistration.find(assignedWorkshopID, on: req.db),
      let lumaEventID = workshop.lumaEventID
    {
      do {
        try await LumaClient.updateGuestStatus(
          eventID: lumaEventID,
          guest: lumaGuestID,
          status: "declined",
          client: req.client,
          logger: req.logger
        )
      } catch {
        req.logger.error(
          "Failed to decline guest on Luma for \(email): \(error). Proceeding with local deletion."
        )
      }
    }

    try await application.delete(on: req.db)
    return WorkshopActionResponseContent(
      action: "cancel",
      message: "Workshop participation cancelled"
    )
  }

  private func verifyWorkshopActionToken(_ token: String, req: Request) async throws
    -> WorkshopVerifyPayload
  {
    do {
      return try await req.jwt.verify(token, as: WorkshopVerifyPayload.self)
    } catch {
      throw Abort(.unauthorized, reason: "Session expired. Please verify your email again.")
    }
  }

  private func applicationInfo(email: String, on req: Request) async throws
    -> WorkshopApplicationInfoContent
  {
    guard
      let application = try await WorkshopApplication.query(on: req.db)
        .filter(\.$email == email)
        .with(\.$firstChoice)
        .with(\.$secondChoice)
        .with(\.$thirdChoice)
        .with(\.$assignedWorkshop)
        .first()
    else {
      throw Abort(.notFound, reason: "Workshop application not found")
    }

    let firstTitle = try await WorkshopAPIService.workshopTitle(
      for: application.$firstChoice.id,
      on: req.db
    ) ?? "Unknown"
    let secondTitle: String? =
      if let id = application.$secondChoice.id {
        try await WorkshopAPIService.workshopTitle(for: id, on: req.db)
      } else {
        nil as String?
      }
    let thirdTitle: String? =
      if let id = application.$thirdChoice.id {
        try await WorkshopAPIService.workshopTitle(for: id, on: req.db)
      } else {
        nil as String?
      }
    let assignedTitle: String? =
      if let id = application.$assignedWorkshop.id {
        try await WorkshopAPIService.workshopTitle(for: id, on: req.db)
      } else {
        nil as String?
      }

    let deleteToken: String? =
      if application.status == .pending {
        try await req.jwt.sign(WorkshopVerifyPayload(email: application.email, name: ""))
      } else {
        nil as String?
      }
    let cancelToken: String? =
      if application.status == .won {
        try await req.jwt.sign(WorkshopVerifyPayload(email: application.email, name: ""))
      } else {
        nil as String?
      }
    let canReapply: Bool
    if application.status == .lost {
      let remaining = try await WorkshopAPIService.computeRemainingCapacity(on: req.db)
      canReapply = remaining.values.contains { $0 > 0 }
    } else {
      canReapply = false
    }

    return WorkshopApplicationInfoContent(
      email: application.email,
      applicantName: application.applicantName,
      status: application.status.rawValue,
      firstChoice: firstTitle,
      secondChoice: secondTitle,
      thirdChoice: thirdTitle,
      assignedWorkshop: assignedTitle,
      canModify: application.status == .pending,
      canReapply: canReapply,
      deleteToken: deleteToken,
      cancelToken: cancelToken,
      createdAt: application.createdAt,
      updatedAt: application.updatedAt
    )
  }
}
