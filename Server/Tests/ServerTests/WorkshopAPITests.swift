import Fluent
import FluentSQLiteDriver
import JWT
import enum SharedModels.FacilityRequirement
import enum SharedModels.ProposalStatus
import enum SharedModels.WorkshopLanguage
import struct SharedModels.WorkshopDetails
import Testing
import Vapor
import VaporTesting

@testable import Server

private struct CreateWorkshopAPITestSchema: AsyncMigration {
  var name: String { "CreateWorkshopAPITestSchema" }

  func prepare(on database: Database) async throws {
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

    try await database.schema(WorkshopRegistration.schema)
      .id()
      .field("proposal_id", .uuid, .required, .references(Proposal.schema, "id", onDelete: .cascade))
      .field("capacity", .int, .required)
      .field("luma_event_id", .string)
      .field("created_at", .datetime)
      .field("updated_at", .datetime)
      .unique(on: "proposal_id")
      .create()

    try await database.schema(WorkshopApplication.schema)
      .id()
      .field("email", .string, .required)
      .field("applicant_name", .string, .required)
      .field("first_choice_id", .uuid, .required, .references(WorkshopRegistration.schema, "id", onDelete: .cascade))
      .field("second_choice_id", .uuid, .references(WorkshopRegistration.schema, "id", onDelete: .cascade))
      .field("third_choice_id", .uuid, .references(WorkshopRegistration.schema, "id", onDelete: .cascade))
      .field("assigned_workshop_id", .uuid, .references(WorkshopRegistration.schema, "id", onDelete: .setNull))
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

@Suite("Workshop API Tests")
struct WorkshopAPITests {
  private let jwtSecret = "workshop-api-test-secret"

  private func makeApp() async throws -> Application {
    let app = try await Application.make(.testing)
    app.databases.use(.sqlite(.memory), as: .sqlite)
    app.migrations.add(CreateWorkshopAPITestSchema())
    try await app.autoMigrate()
    await app.jwt.keys.add(hmac: HMACKey(from: jwtSecret), digestAlgorithm: .sha256)

    let api = app.grouped("api", "v1")
    try api.register(collection: WorkshopController())
    try api.register(collection: AdminWorkshopController())

    return app
  }

  private func withTestApp(_ body: (Application) async throws -> Void) async throws {
    let app = try await makeApp()
    do {
      try await body(app)
    } catch {
      try await app.asyncShutdown()
      throw error
    }
    try await app.asyncShutdown()
  }

  private func makeUserToken(for user: User, on app: Application) async throws -> String {
    try await app.jwt.keys.sign(
      UserJWTPayload(userID: try user.requireID(), role: user.role, username: user.username)
    )
  }

  private func makeWorkshopVerifyToken(email: String, name: String, on app: Application) async throws -> String {
    try await app.jwt.keys.sign(WorkshopVerifyPayload(email: email, name: name))
  }

  private func seedWorkshop(
    on db: Database,
    capacity: Int = 2
  ) async throws -> (conference: Conference, speaker: User, proposal: Proposal, registration: WorkshopRegistration) {
    let speaker = User(githubID: 10, username: "workshop-speaker", role: .speaker)
    try await speaker.save(on: db)

    let conference = Conference(
      path: "tryswift-2026",
      displayName: "try! Swift 2026",
      year: 2026,
      isOpen: true
    )
    try await conference.save(on: db)

    let proposal = Proposal(
      conferenceID: try conference.requireID(),
      title: "Swift Concurrency Workshop",
      abstract: "Build safer workshop flows.",
      talkDetail: "Deep dive into structured concurrency.",
      talkDuration: .workshop,
      speakerName: "Workshop Speaker",
      speakerEmail: "speaker@example.com",
      bio: "Bio",
      speakerID: try speaker.requireID(),
      githubUsername: "workshop-speaker"
    )
    proposal.status = ProposalStatus.accepted
    proposal.workshopDetails = WorkshopDetails(
      language: WorkshopLanguage.english,
      numberOfTutors: 1,
      keyTakeaways: "Concurrency patterns",
      prerequisites: "Swift basics",
      agendaSchedule: "Hands-on",
      participantRequirements: "Laptop",
      requiredSoftware: "Xcode",
      networkRequirements: "Wi-Fi",
      requiredFacilities: [FacilityRequirement.projector],
      facilityOther: nil,
      motivation: "Helpful workshop",
      uniqueness: "Lots of practice",
      potentialRisks: nil
    )
    try await proposal.save(on: db)

    let registration = WorkshopRegistration(
      proposalID: try proposal.requireID(),
      capacity: capacity
    )
    try await registration.save(on: db)

    return (conference, speaker, proposal, registration)
  }

  @Test("public workshop endpoints support apply status and delete flow")
  func applyStatusDeleteFlow() async throws {
    try await withTestApp { app in
      let seeded = try await seedWorkshop(on: app.db, capacity: 2)
      let registrationID = try seeded.registration.requireID()
      let verifyToken = try await makeWorkshopVerifyToken(email: "attendee@example.com", name: "Attendee", on: app)

      try await app.testing().test(.GET, "api/v1/workshops") { response in
        #expect(response.status == .ok)
        let body = try response.content.decode(WorkshopListResponseContent.self)
        #expect(body.applicationOpen)
        #expect(body.workshops.count == 1)
        #expect(body.workshops.first?.registrationID == registrationID)
      }

      try await app.testing().test(
        .POST, "api/v1/workshops/apply",
        beforeRequest: { req in
          try req.content.encode(
            WorkshopApplyRequestContent(
              applicantName: "Attendee",
              verifyToken: verifyToken,
              firstChoiceID: registrationID,
              secondChoiceID: nil,
              thirdChoiceID: nil
            )
          )
        },
        afterResponse: { response in
          #expect(response.status == .ok)
          let body = try response.content.decode(WorkshopApplyResponseContent.self)
          #expect(body.mode == "submitted")
          #expect(!body.isPostLottery)
          #expect(body.application.status == WorkshopApplicationStatus.pending.rawValue)
          #expect(body.application.canModify)
          #expect(body.application.deleteToken != nil)
        }
      )

      var deleteToken: String?
      try await app.testing().test(
        .POST, "api/v1/workshops/status",
        beforeRequest: { req in
          try req.content.encode(WorkshopStatusRequestContent(email: "attendee@example.com"))
        },
        afterResponse: { response in
          #expect(response.status == .ok)
          let body = try response.content.decode(WorkshopStatusResponseContent.self)
          #expect(body.found)
          #expect(body.application?.firstChoice == "Swift Concurrency Workshop")
          deleteToken = body.application?.deleteToken
        }
      )

      let token = try #require(deleteToken)
      try await app.testing().test(
        .POST, "api/v1/workshops/delete",
        beforeRequest: { req in
          try req.content.encode(WorkshopActionTokenRequestContent(token: token))
        },
        afterResponse: { response in
          #expect(response.status == .ok)
          let body = try response.content.decode(WorkshopActionResponseContent.self)
          #expect(body.action == "delete")
        }
      )

      let remaining = try await WorkshopApplication.query(on: app.db).all()
      #expect(remaining.isEmpty)
    }
  }

  @Test("admin workshop endpoints support capacity update lottery and results")
  func adminWorkshopManagementFlow() async throws {
    try await withTestApp { app in
      let seeded = try await seedWorkshop(on: app.db, capacity: 1)
      let registrationID = try seeded.registration.requireID()
      let admin = User(githubID: 99, username: "admin", role: .admin)
      try await admin.save(on: app.db)
      let adminToken = try await makeUserToken(for: admin, on: app)

      let pendingApplication = WorkshopApplication(
        email: "winner@example.com",
        applicantName: "Winner",
        firstChoiceID: registrationID
      )
      try await pendingApplication.save(on: app.db)

      try await app.testing().test(
        .PUT, "api/v1/admin/workshops/\(registrationID.uuidString)/capacity",
        beforeRequest: { req in
          req.headers.bearerAuthorization = .init(token: adminToken)
          try req.content.encode(AdminWorkshopCapacityRequestContent(capacity: 3))
        },
        afterResponse: { response in
          #expect(response.status == .ok)
        }
      )

      try await app.testing().test(
        .POST, "api/v1/admin/workshops/lottery",
        beforeRequest: { req in
          req.headers.bearerAuthorization = .init(token: adminToken)
        },
        afterResponse: { response in
          #expect(response.status == .ok)
          let body = try response.content.decode(LotteryResultContent.self)
          #expect(body.totalApplications == 1)
          #expect(body.assigned == 1)
          #expect(body.unassigned == 0)
        }
      )

      try await app.testing().test(
        .GET, "api/v1/admin/workshops/results",
        beforeRequest: { req in
          req.headers.bearerAuthorization = .init(token: adminToken)
        },
        afterResponse: { response in
          #expect(response.status == .ok)
          let body = try response.content.decode([AdminWorkshopLotteryResultContent].self)
          #expect(body.count == 1)
          #expect(body.first?.winners.count == 1)
          #expect(body.first?.winners.first?.email == "winner@example.com")
        }
      )

      try await app.testing().test(
        .GET, "api/v1/admin/workshops",
        beforeRequest: { req in
          req.headers.bearerAuthorization = .init(token: adminToken)
        },
        afterResponse: { response in
          #expect(response.status == .ok)
          let body = try response.content.decode([AdminWorkshopSummaryContent].self)
          #expect(body.count == 1)
          #expect(body.first?.capacity == 3)
          #expect(body.first?.remainingCapacity == 2)
          #expect(body.first?.winnerEmails == ["winner@example.com"])
        }
      )
    }
  }
}
