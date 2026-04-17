import Fluent
import SharedModels
import Vapor

enum WorkshopAPIService {
  struct FetchedWorkshop: Sendable {
    let registrationID: UUID
    let proposalTitle: String
    let titleJA: String?
    let speakerName: String
    let abstract: String
    let talkDetail: String
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

  enum DirectAssignResult: Sendable {
    case assigned
    case full
  }

  static func computeRemainingCapacity(on db: Database) async throws -> [UUID: Int] {
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

  static func hasLotteryRun(on db: Database) async throws -> Bool {
    try await WorkshopApplication.query(on: db)
      .filter(\.$status != .pending)
      .count() > 0
  }

  static func fetchWorkshops(on db: Database, includeApplicationCount: Bool = true) async throws
    -> [FetchedWorkshop]
  {
    let proposals = try await Proposal.query(on: db)
      .filter(\.$talkDuration == .workshop)
      .filter(\.$status == .accepted)
      .with(\.$speaker)
      .sort(\.$title)
      .all()

    var results: [FetchedWorkshop] = []

    for proposal in proposals {
      guard let proposalID = proposal.id else { continue }

      let registration: WorkshopRegistration
      if let existing = try await WorkshopRegistration.query(on: db)
        .filter(\.$proposal.$id == proposalID)
        .first()
      {
        registration = existing
      } else {
        let newRegistration = WorkshopRegistration(proposalID: proposalID, capacity: 30)
        do {
          try await newRegistration.save(on: db)
          registration = newRegistration
        } catch {
          guard
            let existing = try await WorkshopRegistration.query(on: db)
              .filter(\.$proposal.$id == proposalID)
              .first()
          else { throw error }
          registration = existing
        }
      }

      guard let registrationID = registration.id else { continue }
      let applicationCount =
        includeApplicationCount
        ? try await WorkshopApplication.query(on: db)
          .filter(\.$firstChoice.$id == registrationID)
          .count()
        : 0

      results.append(
        FetchedWorkshop(
          registrationID: registrationID,
          proposalTitle: proposal.title,
          titleJA: proposal.titleJA,
          speakerName: proposal.speakerName,
          abstract: proposal.abstract,
          talkDetail: proposal.talkDetail,
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
          applicationCount: applicationCount,
          lumaEventID: registration.lumaEventID,
          workshopLanguage: proposal.workshopDetails?.language
        ))
    }

    return results
  }

  static func workshopTitle(for registrationID: UUID, on db: Database) async throws -> String? {
    guard
      let registration = try await WorkshopRegistration.query(on: db)
        .filter(\.$id == registrationID)
        .with(\.$proposal)
        .first()
    else { return nil }
    return registration.proposal.title
  }

  static func buildTitleCache(on db: Database) async throws -> [UUID: String] {
    let registrations = try await WorkshopRegistration.query(on: db)
      .with(\.$proposal)
      .all()

    var cache: [UUID: String] = [:]
    for registration in registrations {
      guard let id = registration.id else { continue }
      cache[id] = registration.proposal.title
    }
    return cache
  }

  static func directAssign(
    email: String,
    applicantName: String,
    workshopID: UUID,
    existingApplication: WorkshopApplication?,
    on db: Database
  ) async throws -> DirectAssignResult {
    try await db.transaction { tx in
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

  static func sendLumaInvitation(
    email: String,
    applicantName: String,
    workshopID: UUID,
    db: any Database,
    client: any Client,
    logger: Logger
  ) async {
    do {
      if let existing = try await WorkshopApplication.query(on: db)
        .filter(\.$email == email)
        .filter(\.$status == .won)
        .first(),
        existing.lumaGuestID != nil
      {
        logger.info("FCFS Luma invite: \(email) already has lumaGuestID, skipping")
        return
      }

      guard let workshop = try await WorkshopRegistration.find(workshopID, on: db) else {
        logger.warning("FCFS Luma invite: workshop \(workshopID) not found")
        return
      }
      guard let lumaEventID = workshop.lumaEventID else {
        logger.info("FCFS Luma invite: no lumaEventID for workshop \(workshopID), skipping")
        return
      }

      let ticketTypes = try await LumaClient.getTicketTypes(
        eventID: lumaEventID,
        client: client,
        logger: logger
      )
      guard let standardTicket = ticketTypes.first(where: { $0.name == "Standard" }) else {
        logger.error("FCFS Luma invite: no 'Standard' ticket type for event \(lumaEventID)")
        return
      }

      _ = try await LumaClient.addGuestToEvent(
        eventID: lumaEventID,
        email: email,
        name: applicantName,
        ticketTypeID: standardTicket.id,
        client: client,
        logger: logger
      )

      let guest = try await LumaClient.getGuest(
        email: email,
        eventID: lumaEventID,
        client: client,
        logger: logger
      )

      if let guestID = guest?.id,
        let application = try await WorkshopApplication.query(on: db)
          .filter(\.$email == email)
          .filter(\.$status == .won)
          .first()
      {
        application.lumaGuestID = guestID
        try await application.save(on: db)
        logger.info("FCFS Luma invite: sent and saved guestID for \(email)")
      } else {
        logger.info("FCFS Luma invite: sent for \(email) but could not resolve guestID")
      }
    } catch {
      logger.error("FCFS Luma invite failed for \(email): \(error)")
    }
  }
}
