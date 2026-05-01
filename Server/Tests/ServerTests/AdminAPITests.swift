import Fluent
import FluentSQLiteDriver
import JWT
import Testing
import Vapor
import VaporTesting

import enum SharedModels.ProposalStatus
import enum SharedModels.TalkDuration

@testable import Server

private struct CreateAdminAPITestSchema: AsyncMigration {
  var name: String { "CreateAdminAPITestSchema" }

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
      .field("is_accepting_sponsors", .bool, .required, .sql(.default(false)))
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

    try await database.schema(ScheduleSlot.schema)
      .id()
      .field("conference_id", .uuid, .required, .references(Conference.schema, "id"))
      .field("proposal_id", .uuid, .references(Proposal.schema, "id", onDelete: .setNull))
      .field("day", .int, .required)
      .field("start_time", .datetime, .required)
      .field("end_time", .datetime)
      .field("slot_type", .string, .required)
      .field("custom_title", .string)
      .field("custom_title_ja", .string)
      .field("description_text", .string)
      .field("description_text_ja", .string)
      .field("place", .string)
      .field("place_ja", .string)
      .field("sort_order", .int, .required)
      .field("created_at", .datetime)
      .field("updated_at", .datetime)
      .create()
  }

  func revert(on database: Database) async throws {
    try await database.schema(ScheduleSlot.schema).delete()
    try await database.schema(Proposal.schema).delete()
    try await database.schema(Conference.schema).delete()
    try await database.schema(User.schema).delete()
  }
}

@Suite("Admin API Tests")
struct AdminAPITests {
  private let jwtSecret = "admin-api-test-secret"

  private func makeApp() async throws -> Application {
    let app = try await Application.make(.testing)
    app.databases.use(.sqlite(.memory), as: .sqlite)
    app.migrations.add(CreateAdminAPITestSchema())
    try await app.autoMigrate()
    await app.jwt.keys.add(hmac: HMACKey(from: jwtSecret), digestAlgorithm: .sha256)

    let api = app.grouped("api", "v1")
    try api.register(collection: AdminProposalController())
    try api.register(collection: AdminTimetableController())

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

  private func makeToken(for user: User, on app: Application) async throws -> String {
    try await app.jwt.keys.sign(
      UserJWTPayload(userID: try user.requireID(), role: user.role, username: user.username)
    )
  }

  @Test("admin can create and update proposal status")
  func adminProposalLifecycle() async throws {
    try await withTestApp { app in
      let admin = User(githubID: 100, username: "admin", role: .admin)
      try await admin.save(on: app.db)
      let importUser = User(
        id: AddPaperCallImportUser.paperCallUserID,
        githubID: 0,
        username: "papercall-import",
        role: .speaker
      )
      try await importUser.save(on: app.db)
      let conference = Conference(
        path: "conf-2026", displayName: "Conf 2026", year: 2026, isOpen: true)
      try await conference.save(on: app.db)
      let token = try await makeToken(for: admin, on: app)

      var createdID: UUID?
      try await app.testing().test(
        .POST, "api/v1/admin/proposals",
        beforeRequest: { req in
          req.headers.bearerAuthorization = .init(token: token)
          try req.content.encode(
            AdminProposalRequestContent(
              conferenceId: try conference.requireID(),
              title: "Admin Created",
              abstract: "Abstract",
              talkDetail: "Detail",
              talkDuration: TalkDuration.regular.rawValue,
              speakerName: "Speaker",
              speakerEmail: "speaker@example.com",
              bio: "Bio",
              bioJa: nil,
              jobTitle: nil,
              jobTitleJa: nil,
              iconURL: nil,
              githubUsername: nil,
              notes: nil,
              titleJA: nil,
              abstractJA: nil,
              workshopDetails: nil,
              workshopDetailsJA: nil,
              coInstructors: nil
            ))
        },
        afterResponse: { response in
          #expect(response.status == .ok)
          let body = try response.content.decode(ProposalDTOContent.self)
          createdID = body.id
        }
      )

      let proposalID = try #require(createdID)

      try await app.testing().test(
        .POST, "api/v1/admin/proposals/\(proposalID.uuidString)/status",
        beforeRequest: { req in
          req.headers.bearerAuthorization = .init(token: token)
          try req.content.encode(
            ProposalStatusChangeRequestContent(status: ProposalStatus.accepted.rawValue))
        },
        afterResponse: { response in
          #expect(response.status == .ok)
        }
      )

      let updated = try await Proposal.find(proposalID, on: app.db)
      #expect(updated?.status == .accepted)
    }
  }

  @Test("admin can create timetable slot")
  func adminCanCreateTimetableSlot() async throws {
    try await withTestApp { app in
      let admin = User(githubID: 200, username: "admin", role: .admin)
      try await admin.save(on: app.db)
      let conference = Conference(
        path: "conf-2026", displayName: "Conf 2026", year: 2026, isOpen: true)
      try await conference.save(on: app.db)
      let token = try await makeToken(for: admin, on: app)

      try await app.testing().test(
        .POST, "api/v1/admin/timetable/slots",
        beforeRequest: { req in
          req.headers.bearerAuthorization = .init(token: token)
          try req.content.encode(
            CreateScheduleSlotRequestContent(
              conferenceId: try conference.requireID(),
              proposalId: nil,
              day: 1,
              startTime: "2026-04-10T01:00:00Z",
              endTime: "2026-04-10T02:00:00Z",
              slotType: SlotType.opening.rawValue,
              customTitle: "Opening",
              customTitleJa: nil,
              place: "Main Hall",
              placeJa: nil
            ))
        },
        afterResponse: { response in
          #expect(response.status == .ok)
          let body = try response.content.decode(ScheduleSlotDTO.self)
          #expect(body.slotType == SlotType.opening.rawValue)
          #expect(body.customTitle == "Opening")
        }
      )
    }
  }
}
