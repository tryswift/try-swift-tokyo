import Fluent
import FluentSQLiteDriver
import Foundation
import Testing
import Vapor

@testable import Server

/// SQLite-compatible migration that creates all tables needed for lottery tests.
private struct CreateTestLotterySchema: AsyncMigration {
  var name: String { "CreateTestLotterySchema" }

  func prepare(on database: Database) async throws {
    // Users table (minimal)
    try await database.schema(User.schema)
      .id()
      .field("github_id", .int, .required)
      .field("username", .string, .required)
      .field("role", .string, .required)
      .field("display_name", .string)
      .field("email", .string)
      .field("bio", .string)
      .field("url", .string)
      .field("organization", .string)
      .field("avatar_url", .string)
      .field("created_at", .datetime)
      .field("updated_at", .datetime)
      .create()

    // Conferences table (minimal)
    try await database.schema(Conference.schema)
      .id()
      .field("path", .string, .required)
      .field("display_name", .string, .required)
      .field("description_en", .string)
      .field("description_ja", .string)
      .field("year", .int, .required)
      .field("is_open", .bool, .required)
      .field("deadline", .datetime)
      .field("start_date", .datetime)
      .field("end_date", .datetime)
      .field("location", .string)
      .field("website_url", .string)
      .field("created_at", .datetime)
      .field("updated_at", .datetime)
      .create()

    // Proposals table (minimal for FK)
    try await database.schema(Proposal.schema)
      .id()
      .field("conference_id", .uuid, .required, .references(Conference.schema, "id"))
      .field("title", .string, .required)
      .field("abstract", .string, .required)
      .field("talk_detail", .string, .required)
      .field("talk_duration", .string, .required)
      .field("bio", .string, .required)
      .field("icon_url", .string)
      .field("notes", .string)
      .field("speaker_id", .uuid, .required, .references(User.schema, "id"))
      .field("speaker_name", .string, .required)
      .field("speaker_email", .string, .required)
      .field("papercall_id", .string)
      .field("papercall_username", .string)
      .field("status", .string, .required)
      .field("github_username", .string)
      .field("workshop_details", .json)
      .field("co_instructors", .json)
      .field("title_ja", .string)
      .field("abstract_ja", .string)
      .field("bio_ja", .string)
      .field("job_title", .string)
      .field("job_title_ja", .string)
      .field("workshop_details_ja", .json)
      .field("created_at", .datetime)
      .field("updated_at", .datetime)
      .create()

    // Workshop registrations
    try await database.schema(WorkshopRegistration.schema)
      .id()
      .field(
        "proposal_id", .uuid, .required,
        .references(Proposal.schema, "id", onDelete: .cascade)
      )
      .field("capacity", .int, .required)
      .field("luma_event_id", .string)
      .field("created_at", .datetime)
      .field("updated_at", .datetime)
      .unique(on: "proposal_id")
      .create()

    // Workshop applications
    try await database.schema(WorkshopApplication.schema)
      .id()
      .field("email", .string, .required)
      .field("applicant_name", .string, .required)
      .field(
        "first_choice_id", .uuid, .required,
        .references(WorkshopRegistration.schema, "id", onDelete: .cascade)
      )
      .field(
        "second_choice_id", .uuid,
        .references(WorkshopRegistration.schema, "id", onDelete: .cascade)
      )
      .field(
        "third_choice_id", .uuid,
        .references(WorkshopRegistration.schema, "id", onDelete: .cascade)
      )
      .field(
        "assigned_workshop_id", .uuid,
        .references(WorkshopRegistration.schema, "id", onDelete: .setNull)
      )
      .field("status", .string, .required)
      .field("luma_guest_id", .string)
      .field("created_at", .datetime)
      .field("updated_at", .datetime)
      .unique(on: "email")
      .create()
  }

  func revert(on database: Database) async throws {
    try await database.schema(WorkshopApplication.schema).delete()
    try await database.schema(WorkshopRegistration.schema).delete()
    try await database.schema(Proposal.schema).delete()
    try await database.schema(Conference.schema).delete()
    try await database.schema(User.schema).delete()
  }
}

@Suite("LotteryService Tests")
struct LotteryServiceTests {

  private func makeTestApp() async throws -> Application {
    let app = try await Application.make(.testing)
    app.databases.use(.sqlite(.memory), as: .sqlite)
    app.migrations.add(CreateTestLotterySchema())
    try await app.autoMigrate()
    return app
  }

  /// Create test fixtures: a speaker, conference, and N workshop proposals with registrations.
  private func seedWorkshops(
    count: Int, capacity: Int, on db: Database
  ) async throws -> (speaker: User, conference: Conference, registrations: [WorkshopRegistration]) {
    let speaker = User(githubID: 1, username: "speaker", role: .speaker)
    try await speaker.save(on: db)

    let conference = Conference(
      path: "test-conf-2026", displayName: "Test Conf", year: 2026)
    try await conference.save(on: db)

    var registrations: [WorkshopRegistration] = []
    for i in 0..<count {
      let proposal = Proposal(
        conferenceID: try conference.requireID(),
        title: "Workshop \(i + 1)",
        abstract: "Abstract \(i + 1)",
        talkDetail: "Detail",
        talkDuration: .workshop,
        speakerName: "Speaker",
        speakerEmail: "speaker@test.com",
        bio: "Bio",
        speakerID: try speaker.requireID(),
        status: .accepted
      )
      try await proposal.save(on: db)

      let reg = WorkshopRegistration(
        proposalID: try proposal.requireID(), capacity: capacity)
      try await reg.save(on: db)
      registrations.append(reg)
    }
    return (speaker, conference, registrations)
  }

  // MARK: - Basic lottery tests

  @Test("lottery with no applications returns zero results")
  func lotteryNoApplications() async throws {
    let app = try await makeTestApp()
    defer { Task { try? await app.asyncShutdown() } }

    let _ = try await seedWorkshops(count: 2, capacity: 10, on: app.db)
    let result = try await LotteryService.runLottery(on: app.db)

    #expect(result.totalApplications == 0)
    #expect(result.assigned == 0)
    #expect(result.unassigned == 0)
  }

  @Test("all applicants get first choice when capacity is sufficient")
  func allGetFirstChoice() async throws {
    let app = try await makeTestApp()
    defer { Task { try? await app.asyncShutdown() } }

    let (_, _, regs) = try await seedWorkshops(count: 2, capacity: 10, on: app.db)

    // 3 applicants all choose workshop 1 as first choice (capacity=10)
    for i in 0..<3 {
      let application = WorkshopApplication(
        email: "user\(i)@test.com",
        applicantName: "User \(i)",
        firstChoiceID: try regs[0].requireID(),
        secondChoiceID: try regs[1].requireID()
      )
      try await application.save(on: app.db)
    }

    let result = try await LotteryService.runLottery(on: app.db)

    #expect(result.totalApplications == 3)
    #expect(result.assigned == 3)
    #expect(result.unassigned == 0)

    // All should be assigned to first choice
    let apps = try await WorkshopApplication.query(on: app.db).all()
    for a in apps {
      #expect(a.status == .won)
      #expect(a.$assignedWorkshop.id == a.$firstChoice.id)
    }
  }

  @Test("first choice winners don't participate in second choice round")
  func firstChoiceWinnersExcludedFromSecondRound() async throws {
    let app = try await makeTestApp()
    defer { Task { try? await app.asyncShutdown() } }

    let (_, _, regs) = try await seedWorkshops(count: 2, capacity: 1, on: app.db)
    let regID0 = try regs[0].requireID()
    let regID1 = try regs[1].requireID()

    // 2 applicants both want workshop 0 first, workshop 1 second. Capacity=1 each.
    let app1 = WorkshopApplication(
      email: "a@test.com", applicantName: "A",
      firstChoiceID: regID0, secondChoiceID: regID1)
    let app2 = WorkshopApplication(
      email: "b@test.com", applicantName: "B",
      firstChoiceID: regID0, secondChoiceID: regID1)
    try await app1.save(on: app.db)
    try await app2.save(on: app.db)

    let result = try await LotteryService.runLottery(on: app.db)

    #expect(result.totalApplications == 2)
    #expect(result.assigned == 2)
    #expect(result.unassigned == 0)

    // One should get workshop 0, other should fall through to workshop 1
    let final1 = try await WorkshopApplication.find(app1.id, on: app.db)
    let final2 = try await WorkshopApplication.find(app2.id, on: app.db)
    let assignedIDs: Set<UUID> = Set(
      [final1?.$assignedWorkshop.id, final2?.$assignedWorkshop.id].compactMap { $0 })
    #expect(assignedIDs == Set<UUID>([regID0, regID1]))
    #expect(final1?.status == .won)
    #expect(final2?.status == .won)
  }

  @Test("applicants are marked as lost when all choices are full")
  func applicantsMarkedLost() async throws {
    let app = try await makeTestApp()
    defer { Task { try? await app.asyncShutdown() } }

    let (_, _, regs) = try await seedWorkshops(count: 1, capacity: 1, on: app.db)
    let regID = try regs[0].requireID()

    // 3 applicants, only 1 slot
    for i in 0..<3 {
      let application = WorkshopApplication(
        email: "user\(i)@test.com", applicantName: "User \(i)",
        firstChoiceID: regID)
      try await application.save(on: app.db)
    }

    let result = try await LotteryService.runLottery(on: app.db)

    #expect(result.totalApplications == 3)
    #expect(result.assigned == 1)
    #expect(result.unassigned == 2)

    let winners = try await WorkshopApplication.query(on: app.db)
      .filter(\.$status == .won).all()
    let losers = try await WorkshopApplication.query(on: app.db)
      .filter(\.$status == .lost).all()

    #expect(winners.count == 1)
    #expect(losers.count == 2)
  }

  @Test("third choice is used when first and second are full")
  func thirdChoiceFallback() async throws {
    let app = try await makeTestApp()
    defer { Task { try? await app.asyncShutdown() } }

    let (_, _, regs) = try await seedWorkshops(count: 3, capacity: 1, on: app.db)
    let regID0 = try regs[0].requireID()
    let regID1 = try regs[1].requireID()
    let regID2 = try regs[2].requireID()

    // First applicant takes workshop 0
    let filler0 = WorkshopApplication(
      email: "filler0@test.com", applicantName: "Filler0", firstChoiceID: regID0)
    try await filler0.save(on: app.db)

    // Second applicant takes workshop 1
    let filler1 = WorkshopApplication(
      email: "filler1@test.com", applicantName: "Filler1", firstChoiceID: regID1)
    try await filler1.save(on: app.db)

    // Third applicant wants 0 > 1 > 2, should end up in 2
    let applicant = WorkshopApplication(
      email: "test@test.com", applicantName: "Test",
      firstChoiceID: regID0, secondChoiceID: regID1, thirdChoiceID: regID2)
    try await applicant.save(on: app.db)

    // Use deterministic ordering (insertion order) so fillers fill workshops 0 and 1
    // before the applicant is processed, ensuring the applicant falls through to choice 3
    let result = try await LotteryService.runLottery(on: app.db, shuffle: { $0 })

    #expect(result.totalApplications == 3)
    #expect(result.assigned == 3)
    #expect(result.unassigned == 0)

    let reloaded = try await WorkshopApplication.find(applicant.id, on: app.db)
    #expect(reloaded?.status == .won)
    #expect(reloaded?.$assignedWorkshop.id == regID2)
  }

  @Test("lottery only processes pending applications")
  func onlyPendingProcessed() async throws {
    let app = try await makeTestApp()
    defer { Task { try? await app.asyncShutdown() } }

    let (_, _, regs) = try await seedWorkshops(count: 1, capacity: 10, on: app.db)
    let regID = try regs[0].requireID()

    // Already-won application should not be re-processed
    let wonApp = WorkshopApplication(
      email: "won@test.com", applicantName: "Won",
      firstChoiceID: regID, status: .won)
    wonApp.$assignedWorkshop.id = regID
    try await wonApp.save(on: app.db)

    // Pending application
    let pendingApp = WorkshopApplication(
      email: "pending@test.com", applicantName: "Pending",
      firstChoiceID: regID)
    try await pendingApp.save(on: app.db)

    let result = try await LotteryService.runLottery(on: app.db)

    #expect(result.totalApplications == 1)
    #expect(result.assigned == 1)

    let reloaded = try await WorkshopApplication.find(pendingApp.id, on: app.db)
    #expect(reloaded?.status == .won)
  }

  @Test("lottery respects capacity limits per workshop")
  func respectsCapacityLimits() async throws {
    let app = try await makeTestApp()
    defer { Task { try? await app.asyncShutdown() } }

    let (_, _, regs) = try await seedWorkshops(count: 1, capacity: 2, on: app.db)
    let regID = try regs[0].requireID()

    // 5 applicants, capacity 2
    for i in 0..<5 {
      let application = WorkshopApplication(
        email: "user\(i)@test.com", applicantName: "User \(i)",
        firstChoiceID: regID)
      try await application.save(on: app.db)
    }

    let result = try await LotteryService.runLottery(on: app.db)

    #expect(result.totalApplications == 5)
    #expect(result.assigned == 2)
    #expect(result.unassigned == 3)
  }
}
