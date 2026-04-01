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
  static func runLottery(
    on database: Database,
    shuffle: (@Sendable ([WorkshopApplication]) -> [WorkshopApplication])? = nil
  ) async throws -> LotteryResult {
    try await database.transaction { tx in
      // Fetch all workshops with their capacity
      let workshops = try await WorkshopRegistration.query(on: tx)
        .with(\.$proposal)
        .all()

      // Build capacity tracker: workshopID -> remaining slots
      // Subtract already-won applications to support running lottery after FCFS assignments
      let existingWon = try await WorkshopApplication.query(on: tx)
        .filter(\.$status == .won)
        .all()
      let wonCounts: [UUID?: Int] = Dictionary(grouping: existingWon) { $0.$assignedWorkshop.id }
        .mapValues(\.count)

      var remainingCapacity: [UUID: Int] = [:]
      for workshop in workshops {
        guard let id = workshop.id else { continue }
        remainingCapacity[id] = max(0, workshop.capacity - (wonCounts[id] ?? 0))
      }

      // Fetch all pending applications
      let applications = try await WorkshopApplication.query(on: tx)
        .filter(\.$status == .pending)
        .all()

      // Shuffle for fairness
      let doShuffle = shuffle ?? { $0.shuffled() }
      var shuffled = doShuffle(applications)

      var assigned: [(application: WorkshopApplication, workshopID: UUID)] = []

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
      shuffled = doShuffle(stillUnassigned)
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
      shuffled = doShuffle(stillUnassigned)
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

      let unassigned = stillUnassigned

      // Save results
      for (app, workshopID) in assigned {
        app.$assignedWorkshop.id = workshopID
        app.status = .won
        try await app.save(on: tx)
      }

      for app in unassigned {
        app.status = .lost
        try await app.save(on: tx)
      }

      return LotteryResult(
        totalApplications: applications.count,
        assigned: assigned.count,
        unassigned: unassigned.count
      )
    }
  }
}

/// Result summary of a lottery run
struct LotteryResult: Sendable {
  let totalApplications: Int
  let assigned: Int
  let unassigned: Int
}
