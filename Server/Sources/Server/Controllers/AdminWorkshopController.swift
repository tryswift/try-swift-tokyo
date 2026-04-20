import Fluent
import Vapor

struct AdminWorkshopLotteryWinnerContent: Content {
  let name: String
  let email: String
}

struct AdminWorkshopSummaryContent: Content {
  let registrationID: UUID
  let proposalTitle: String
  let speakerName: String
  let capacity: Int
  let applicationCount: Int
  let remainingCapacity: Int
  let lumaEventID: String?
  let winnerEmails: [String]
}

struct AdminWorkshopCapacityRequestContent: Content {
  let capacity: Int
}

struct AdminWorkshopLumaEventRequestContent: Content {
  let lumaEventID: String?
}

struct AdminWorkshopApplicationRowContent: Content {
  let id: UUID
  let email: String
  let applicantName: String
  let firstChoice: String
  let secondChoice: String?
  let thirdChoice: String?
  let status: String
  let assignedWorkshop: String?
  let createdAt: Date?
}

struct AdminWorkshopLotteryResultContent: Content {
  let workshopTitle: String
  let capacity: Int
  let lumaEventID: String?
  let ticketsSent: Bool
  let winners: [AdminWorkshopLotteryWinnerContent]
}

struct AdminWorkshopOperationResponseContent: Content {
  let message: String
}

struct AdminWorkshopSendTicketsResponseContent: Content {
  let sent: Int
  let skipped: Int
  let errors: Int
}

struct LotteryResultContent: Content {
  let totalApplications: Int
  let assigned: Int
  let unassigned: Int
}

struct AdminWorkshopController: RouteCollection {
  func boot(routes: RoutesBuilder) throws {
    let admin = routes.grouped("admin")
      .grouped(AuthMiddleware())
      .grouped(OrganizerMiddleware())

    let workshops = admin.grouped("workshops")
    workshops.get(use: getWorkshops)
    workshops.put(":registrationID", "capacity", use: setCapacity)
    workshops.post(":registrationID", "create-luma-event", use: createLumaEvent)
    workshops.put(":registrationID", "luma-event", use: setLumaEvent)
    workshops.post("lottery", use: runLottery)
    workshops.get("results", use: results)
    workshops.post("send-tickets", use: sendTickets)

    admin.get("workshop-applications", use: getApplications)
    admin.delete("workshop-applications", ":applicationID", use: deleteApplication)
  }

  @Sendable
  func getWorkshops(req: Request) async throws -> [AdminWorkshopSummaryContent] {
    let workshops = try await WorkshopAPIService.fetchWorkshops(on: req.db)
    let remaining = try await WorkshopAPIService.computeRemainingCapacity(on: req.db)
    let allWinners = try await WorkshopApplication.query(on: req.db)
      .filter(\.$status == .won)
      .all()
    let winnersByWorkshop = Dictionary(grouping: allWinners) { $0.$assignedWorkshop.id }

    return workshops.map {
      AdminWorkshopSummaryContent(
        registrationID: $0.registrationID,
        proposalTitle: $0.proposalTitle,
        speakerName: $0.speakerName,
        capacity: $0.capacity,
        applicationCount: $0.applicationCount,
        remainingCapacity: remaining[$0.registrationID] ?? $0.capacity,
        lumaEventID: $0.lumaEventID,
        winnerEmails: (winnersByWorkshop[$0.registrationID] ?? []).map(\.email)
      )
    }
  }

  @Sendable
  func setCapacity(req: Request) async throws -> AdminWorkshopOperationResponseContent {
    guard let registrationID = req.parameters.get("registrationID", as: UUID.self) else {
      throw Abort(.badRequest, reason: "Invalid registration ID")
    }

    let content = try req.content.decode(AdminWorkshopCapacityRequestContent.self)
    guard content.capacity >= 1, content.capacity <= 1000 else {
      throw Abort(.badRequest, reason: "Capacity must be between 1 and 1000")
    }

    guard let registration = try await WorkshopRegistration.find(registrationID, on: req.db) else {
      throw Abort(.notFound, reason: "Workshop registration not found")
    }

    registration.capacity = content.capacity
    try await registration.save(on: req.db)
    return AdminWorkshopOperationResponseContent(message: "Capacity updated")
  }

  @Sendable
  func createLumaEvent(req: Request) async throws -> AdminWorkshopOperationResponseContent {
    guard let registrationID = req.parameters.get("registrationID", as: UUID.self) else {
      throw Abort(.badRequest, reason: "Invalid registration ID")
    }

    guard
      let registration = try await WorkshopRegistration.query(on: req.db)
        .filter(\.$id == registrationID)
        .with(\.$proposal)
        .first()
    else {
      throw Abort(.notFound, reason: "Workshop registration not found")
    }

    if let existingEventID = registration.lumaEventID {
      return AdminWorkshopOperationResponseContent(
        message: "Luma event already exists: \(existingEventID)"
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
    return AdminWorkshopOperationResponseContent(
      message: "Luma event created: \(eventResponse.id)"
    )
  }

  @Sendable
  func setLumaEvent(req: Request) async throws -> AdminWorkshopOperationResponseContent {
    guard let registrationID = req.parameters.get("registrationID", as: UUID.self) else {
      throw Abort(.badRequest, reason: "Invalid registration ID")
    }

    let content = try req.content.decode(AdminWorkshopLumaEventRequestContent.self)
    guard let registration = try await WorkshopRegistration.find(registrationID, on: req.db) else {
      throw Abort(.notFound, reason: "Workshop registration not found")
    }

    let trimmed = (content.lumaEventID ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
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
    return AdminWorkshopOperationResponseContent(message: "Luma event ID updated")
  }

  @Sendable
  func getApplications(req: Request) async throws -> [AdminWorkshopApplicationRowContent] {
    let workshopFilter = req.query[String.self, at: "workshop"]
    let applications = try await WorkshopApplication.query(on: req.db)
      .with(\.$firstChoice)
      .with(\.$secondChoice)
      .with(\.$thirdChoice)
      .with(\.$assignedWorkshop)
      .sort(\.$createdAt, .descending)
      .all()

    let titleCache = try await WorkshopAPIService.buildTitleCache(on: req.db)
    let rows = applications.compactMap { application -> AdminWorkshopApplicationRowContent? in
      guard let id = application.id else { return nil }
      return AdminWorkshopApplicationRowContent(
        id: id,
        email: application.email,
        applicantName: application.applicantName,
        firstChoice: titleCache[application.$firstChoice.id] ?? "Unknown",
        secondChoice: application.$secondChoice.id.flatMap { titleCache[$0] },
        thirdChoice: application.$thirdChoice.id.flatMap { titleCache[$0] },
        status: application.status.rawValue,
        assignedWorkshop: application.$assignedWorkshop.id.flatMap { titleCache[$0] },
        createdAt: application.createdAt
      )
    }

    guard let workshopFilter, let filterUUID = UUID(uuidString: workshopFilter) else {
      return rows
    }

    let filteredIDs = Set(
      applications.filter { application in
        application.$firstChoice.id == filterUUID
          || application.$secondChoice.id == filterUUID
          || application.$thirdChoice.id == filterUUID
      }.compactMap(\.id)
    )
    return rows.filter { filteredIDs.contains($0.id) }
  }

  @Sendable
  func runLottery(req: Request) async throws -> LotteryResultContent {
    let result = try await LotteryService.runLottery(on: req.db)
    return LotteryResultContent(
      totalApplications: result.totalApplications,
      assigned: result.assigned,
      unassigned: result.unassigned
    )
  }

  @Sendable
  func results(req: Request) async throws -> [AdminWorkshopLotteryResultContent] {
    let workshops = try await WorkshopRegistration.query(on: req.db)
      .with(\.$proposal)
      .all()

    var results: [AdminWorkshopLotteryResultContent] = []
    for workshop in workshops {
      guard let workshopID = workshop.id else { continue }
      let winners = try await WorkshopApplication.query(on: req.db)
        .filter(\.$assignedWorkshop.$id == workshopID)
        .filter(\.$status == .won)
        .all()
      let ticketsSent = winners.allSatisfy { $0.lumaGuestID != nil }

      results.append(
        AdminWorkshopLotteryResultContent(
          workshopTitle: workshop.proposal.title,
          capacity: workshop.capacity,
          lumaEventID: workshop.lumaEventID,
          ticketsSent: !winners.isEmpty && ticketsSent,
          winners: winners.map {
            AdminWorkshopLotteryWinnerContent(name: $0.applicantName, email: $0.email)
          }
        )
      )
    }

    return results
  }

  @Sendable
  func deleteApplication(req: Request) async throws -> HTTPStatus {
    guard let applicationID = req.parameters.get("applicationID", as: UUID.self) else {
      throw Abort(.badRequest, reason: "Invalid application ID")
    }

    guard let application = try await WorkshopApplication.find(applicationID, on: req.db) else {
      throw Abort(.notFound, reason: "Application not found")
    }

    try await application.delete(on: req.db)
    return .noContent
  }

  @Sendable
  func sendTickets(req: Request) async throws -> AdminWorkshopSendTicketsResponseContent {
    let winners = try await WorkshopApplication.query(on: req.db)
      .filter(\.$status == .won)
      .filter(\.$lumaGuestID == nil)
      .with(\.$assignedWorkshop)
      .all()

    var sent = 0
    var skipped = 0
    var errors = 0

    var winnersByEvent: [String: [WorkshopApplication]] = [:]
    for winner in winners {
      guard let workshop = winner.assignedWorkshop,
        let lumaEventID = workshop.lumaEventID
      else { continue }
      winnersByEvent[lumaEventID, default: []].append(winner)
    }

    for (lumaEventID, eventWinners) in winnersByEvent {
      var existingEmails: [String: String] = [:]
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
        req.logger.error("Failed to fetch existing guests for event \(lumaEventID): \(error)")
      }

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
        req.logger.error("Failed to fetch ticket types for event \(lumaEventID): \(error)")
        errors += newWinners.count
        continue
      }

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
          "Failed to batch-add \(guestInputs.count) guests to event \(lumaEventID): \(error)"
        )
        errors += newWinners.count
        continue
      }

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
              "Guest \(winner.email) not found in Luma after batch add for event \(lumaEventID)"
            )
            errors += 1
          }
        }
      } catch {
        req.logger.error(
          "Failed to re-fetch guests after batch add for event \(lumaEventID): \(error)"
        )
        sent += newWinners.count
      }
    }

    return AdminWorkshopSendTicketsResponseContent(sent: sent, skipped: skipped, errors: errors)
  }
}
