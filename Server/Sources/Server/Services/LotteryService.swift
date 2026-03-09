import Fluent
import Vapor

/// Service to run the workshop lottery
enum LotteryService {

  /// Run the lottery for all pending workshop applications
  /// Algorithm:
  /// 1. Shuffle all pending applications
  /// 2. Assign first-choice workshops up to capacity
  /// 3. For unassigned applicants, try second choice
  /// 4. For still-unassigned, try third choice
  /// 5. Mark remaining as lost
  static func runLottery(on database: Database) async throws -> LotteryResult {
    // Fetch all workshops with their capacity
    let workshops = try await WorkshopRegistration.query(on: database)
      .with(\.$proposal)
      .all()

    // Build capacity tracker: workshopID -> remaining slots
    var remainingCapacity: [UUID: Int] = [:]
    for workshop in workshops {
      guard let id = workshop.id else { continue }
      remainingCapacity[id] = workshop.capacity
    }

    // Fetch all pending applications
    let applications = try await WorkshopApplication.query(on: database)
      .filter(\.$status == .pending)
      .all()

    // Shuffle for fairness
    var shuffled = applications.shuffled()

    var assigned: [(application: WorkshopApplication, workshopID: UUID)] = []
    var unassigned: [WorkshopApplication] = []

    // Round 1: First choice
    var stillUnassigned: [WorkshopApplication] = []
    for app in shuffled {
      let choiceID = app.$firstChoice.id
      if let remaining = remainingCapacity[choiceID], remaining > 0 {
        remainingCapacity[choiceID] = remaining - 1
        assigned.append((application: app, workshopID: choiceID))
      } else {
        stillUnassigned.append(app)
      }
    }

    // Round 2: Second choice
    shuffled = stillUnassigned.shuffled()
    stillUnassigned = []
    for app in shuffled {
      if let choiceID = app.$secondChoice.id,
        let remaining = remainingCapacity[choiceID], remaining > 0
      {
        remainingCapacity[choiceID] = remaining - 1
        assigned.append((application: app, workshopID: choiceID))
      } else {
        stillUnassigned.append(app)
      }
    }

    // Round 3: Third choice
    shuffled = stillUnassigned.shuffled()
    stillUnassigned = []
    for app in shuffled {
      if let choiceID = app.$thirdChoice.id,
        let remaining = remainingCapacity[choiceID], remaining > 0
      {
        remainingCapacity[choiceID] = remaining - 1
        assigned.append((application: app, workshopID: choiceID))
      } else {
        stillUnassigned.append(app)
      }
    }

    unassigned = stillUnassigned

    // Save results
    for (app, workshopID) in assigned {
      app.$assignedWorkshop.id = workshopID
      app.status = .won
      try await app.save(on: database)
    }

    for app in unassigned {
      app.status = .lost
      try await app.save(on: database)
    }

    return LotteryResult(
      totalApplications: applications.count,
      assigned: assigned.count,
      unassigned: unassigned.count
    )
  }
}

/// Result summary of a lottery run
struct LotteryResult: Sendable {
  let totalApplications: Int
  let assigned: Int
  let unassigned: Int
}
