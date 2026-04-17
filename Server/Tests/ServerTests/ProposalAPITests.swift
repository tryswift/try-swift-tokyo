import Fluent
import FluentSQLiteDriver
import Foundation
import JWT
import enum SharedModels.FacilityRequirement
import enum SharedModels.TalkDuration
import struct SharedModels.WorkshopDetails
import Testing
import Vapor
import VaporTesting

@testable import Server

private struct CreateProposalAPITestSchema: AsyncMigration {
  var name: String { "CreateProposalAPITestSchema" }

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
  }

  func revert(on database: Database) async throws {
    try await database.schema(Proposal.schema).delete()
    try await database.schema(Conference.schema).delete()
    try await database.schema(User.schema).delete()
  }
}

@Suite("Proposal API Tests")
struct ProposalAPITests {
  private let jwtSecret = "proposal-api-test-secret"

  private func makeApp() async throws -> Application {
    let app = try await Application.make(.testing)
    app.databases.use(.sqlite(.memory), as: .sqlite)
    app.migrations.add(CreateProposalAPITestSchema())
    try await app.autoMigrate()
    await app.jwt.keys.add(hmac: HMACKey(from: jwtSecret), digestAlgorithm: .sha256)

    let api = app.grouped("api", "v1")
    try api.register(collection: ProposalController())
    try api.register(collection: AuthController())

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

  private func seedProposal(on db: Database) async throws -> (speaker: User, conference: Conference, proposal: Proposal) {
    let user = User(githubID: 1, username: "speaker", role: .speaker)
    try await user.save(on: db)

    let conference = Conference(
      path: "tryswift-2026",
      displayName: "try! Swift 2026",
      year: 2026,
      isOpen: true
    )
    try await conference.save(on: db)

    let proposal = Proposal(
      conferenceID: try conference.requireID(),
      title: "Original Title",
      abstract: "Original abstract",
      talkDetail: "Original details",
      talkDuration: .regular,
      speakerName: "Original Speaker",
      speakerEmail: "speaker@example.com",
      bio: "Original bio",
      iconURL: "https://example.com/original.png",
      speakerID: try user.requireID(),
      githubUsername: "speaker"
    )
    try await proposal.save(on: db)

    return (user, conference, proposal)
  }

  private func token(for user: User, on app: Application) async throws -> String {
    try await app.jwt.keys.sign(
      UserJWTPayload(
        userID: try user.requireID(),
        role: user.role,
        username: user.username
      ))
  }

  @Test("speaker can update own proposal through API")
  func updateOwnProposal() async throws {
    try await withTestApp { app in
      let (speaker, conference, proposal) = try await seedProposal(on: app.db)
      let token = try await token(for: speaker, on: app)
      let proposalID = try proposal.requireID()

      try await app.testing().test(
        .PUT, "api/v1/proposals/\(proposalID.uuidString)",
        beforeRequest: { req in
          req.headers.bearerAuthorization = .init(token: token)
          try req.content.encode(
            UpdateProposalRequestContent(
              title: "Updated Title",
              abstract: "Updated abstract",
              talkDetail: "Updated details",
              talkDuration: TalkDuration.workshop.rawValue,
              githubUsername: "speaker-renamed",
              speakerName: "Updated Speaker",
              speakerEmail: "updated@example.com",
              bio: "Updated bio",
              bioJa: "更新済みの自己紹介",
              jobTitle: "Engineer",
              jobTitleJa: "エンジニア",
              iconURL: "https://example.com/updated.png",
              notes: "Updated notes",
              workshopDetails: WorkshopDetails(
                language: .english,
                numberOfTutors: 2,
                keyTakeaways: "Takeaways",
                prerequisites: "Laptop",
                agendaSchedule: "Agenda",
                participantRequirements: "Requirements",
                requiredSoftware: "Xcode",
                networkRequirements: "Wi-Fi",
                requiredFacilities: [FacilityRequirement.projector],
                facilityOther: nil,
                motivation: "Motivation",
                uniqueness: "Uniqueness",
                potentialRisks: nil
              ),
              coInstructors: nil
            ))
        },
        afterResponse: { response in
          #expect(response.status == .ok)
          let body = try response.content.decode(ProposalDTOContent.self)
          #expect(body.title == "Updated Title")
          #expect(body.talkDuration == TalkDuration.workshop.rawValue)
          #expect(body.workshopDetails?.numberOfTutors == 2)
          #expect(body.coInstructors == nil)
        }
      )

      let updated = try await Proposal.query(on: app.db)
        .filter(\.$id == proposalID)
        .with(\.$conference)
        .first()
      #expect(updated?.title == "Updated Title")
      #expect(updated?.talkDuration == .workshop)
      #expect(updated?.githubUsername == "speaker-renamed")
      #expect(updated?.$conference.id == conference.id)
    }
  }

  @Test("speaker cannot update another speaker's proposal")
  func updateOtherUsersProposalFails() async throws {
    try await withTestApp { app in
      let (_, _, proposal) = try await seedProposal(on: app.db)
      let intruder = User(githubID: 2, username: "intruder", role: .speaker)
      try await intruder.save(on: app.db)
      let token = try await token(for: intruder, on: app)
      let proposalID = try proposal.requireID()

      try await app.testing().test(
        .PUT, "api/v1/proposals/\(proposalID.uuidString)",
        beforeRequest: { req in
          req.headers.bearerAuthorization = .init(token: token)
          try req.content.encode(
            UpdateProposalRequestContent(
              title: "Hacked",
              abstract: nil,
              talkDetail: nil,
              talkDuration: nil,
              githubUsername: nil,
              speakerName: nil,
              speakerEmail: nil,
              bio: nil,
              bioJa: nil,
              jobTitle: nil,
              jobTitleJa: nil,
              iconURL: nil,
              notes: nil,
              workshopDetails: nil,
              coInstructors: nil
            ))
        },
        afterResponse: { response in
          #expect(response.status == .notFound)
        }
      )
    }
  }

  @Test("speaker can withdraw own proposal through API")
  func withdrawOwnProposal() async throws {
    try await withTestApp { app in
      let (speaker, _, proposal) = try await seedProposal(on: app.db)
      let token = try await token(for: speaker, on: app)
      let proposalID = try proposal.requireID()

      try await app.testing().test(
        .POST, "api/v1/proposals/\(proposalID.uuidString)/withdraw",
        beforeRequest: { req in
          req.headers.bearerAuthorization = .init(token: token)
        },
        afterResponse: { response in
          #expect(response.status == .ok)
        }
      )

      let updated = try await Proposal.find(proposalID, on: app.db)
      #expect(updated?.status == .withdrawn)
    }
  }

  @Test("logout clears auth cookies through API")
  func logoutClearsCookies() async throws {
    try await withTestApp { app in
      let (speaker, _, _) = try await seedProposal(on: app.db)
      let token = try await token(for: speaker, on: app)

      try await app.testing().test(
        .POST, "api/v1/auth/logout",
        beforeRequest: { req in
          req.headers.bearerAuthorization = .init(token: token)
        },
        afterResponse: { response in
          #expect(response.status == .ok)
          let authCookie = response.headers.setCookie?["auth_token"]
          let usernameCookie = response.headers.setCookie?["auth_username"]
          #expect(authCookie != nil)
          #expect(usernameCookie != nil)
          #expect(authCookie?.maxAge == 0)
          #expect(usernameCookie?.maxAge == 0)
        }
      )
    }
  }
}
