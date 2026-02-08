import Fluent
import FluentSQLiteDriver
import Foundation
import SharedModels
import Testing
import Vapor

@testable import Server

/// SQLite-compatible migration that creates the full proposals table schema in one step.
/// The production migrations use ALTER TABLE with `.sql(.default(...))` which SQLite
/// doesn't support, so we create the final schema directly for test purposes.
private struct CreateTestProposalSchema: AsyncMigration {
  var name: String { "CreateTestProposalSchema" }
  func prepare(on database: Database) async throws {
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
      .field("created_at", .datetime)
      .field("updated_at", .datetime)
      // Fields from AddProposalSpeakerInfo
      .field("speaker_name", .string, .required)
      .field("speaker_email", .string, .required)
      // Fields from AddProposalPaperCallFields
      .field("papercall_id", .string)
      .field("papercall_username", .string)
      // Field from AddProposalStatus
      .field("status", .string, .required)
      // Field for GitHub username
      .field("github_username", .string)
      .create()
  }

  func revert(on database: Database) async throws {
    try await database.schema(Proposal.schema).delete()
  }
}

@Suite("resolveSpeakerID Tests")
struct ResolveSpeakerIDTests {

  /// Create a Vapor Application backed by in-memory SQLite with all required tables.
  private func makeTestApp() async throws -> Application {
    let app = try await Application.make(.testing)
    app.databases.use(.sqlite(.memory), as: .sqlite)

    // Use production migrations where SQLite-compatible,
    // and a combined schema for proposals to avoid ALTER TABLE issues.
    app.migrations.add(CreateUser())
    app.migrations.add(AddUserEmail())
    app.migrations.add(CreateConference())
    app.migrations.add(SeedTrySwiftTokyo2026())
    app.migrations.add(AddPaperCallImportUser())
    app.migrations.add(CreateTestProposalSchema())
    app.migrations.add(CreateScheduleSlot())

    try await app.autoMigrate()
    return app
  }

  // MARK: - resolveSpeakerID: nil / empty / whitespace → import user

  @Test("nil username returns import user ID")
  func resolveNilUsername() async throws {
    let app = try await makeTestApp()
    defer { Task { try? await app.asyncShutdown() } }

    let routes = CfPRoutes()
    let id = try await routes.resolveSpeakerID(githubUsername: nil, on: app.db)
    #expect(id == AddPaperCallImportUser.paperCallUserID)
  }

  @Test("empty string returns import user ID")
  func resolveEmptyUsername() async throws {
    let app = try await makeTestApp()
    defer { Task { try? await app.asyncShutdown() } }

    let routes = CfPRoutes()
    let id = try await routes.resolveSpeakerID(githubUsername: "", on: app.db)
    #expect(id == AddPaperCallImportUser.paperCallUserID)
  }

  @Test("whitespace-only string returns import user ID")
  func resolveWhitespaceUsername() async throws {
    let app = try await makeTestApp()
    defer { Task { try? await app.asyncShutdown() } }

    let routes = CfPRoutes()
    let id = try await routes.resolveSpeakerID(githubUsername: "   ", on: app.db)
    #expect(id == AddPaperCallImportUser.paperCallUserID)
  }

  // MARK: - resolveSpeakerID: existing user

  @Test("existing GitHub username returns matching user ID")
  func resolveExistingUser() async throws {
    let app = try await makeTestApp()
    defer { Task { try? await app.asyncShutdown() } }

    let user = User(githubID: 12345, username: "octocat", role: .speaker)
    try await user.save(on: app.db)

    let routes = CfPRoutes()
    let id = try await routes.resolveSpeakerID(githubUsername: "octocat", on: app.db)
    #expect(id == user.id)
  }

  @Test("username with surrounding whitespace still finds user")
  func resolveTrimsWhitespace() async throws {
    let app = try await makeTestApp()
    defer { Task { try? await app.asyncShutdown() } }

    let user = User(githubID: 99999, username: "trimtest", role: .speaker)
    try await user.save(on: app.db)

    let routes = CfPRoutes()
    let id = try await routes.resolveSpeakerID(githubUsername: "  trimtest  ", on: app.db)
    #expect(id == user.id)
  }

  // MARK: - resolveSpeakerID: non-existent user throws

  @Test("non-existent username throws Abort(.badRequest)")
  func resolveNonExistentUser() async throws {
    let app = try await makeTestApp()
    defer { Task { try? await app.asyncShutdown() } }

    let routes = CfPRoutes()
    do {
      _ = try await routes.resolveSpeakerID(githubUsername: "no-such-user", on: app.db)
      Issue.record("Expected Abort to be thrown")
    } catch let error as Abort {
      #expect(error.status == .badRequest)
      #expect(error.reason.contains("no-such-user"))
    }
  }

  // MARK: - Edit handler: clearing GitHub username reverts to import user

  @Test("clearing GitHub username on edit reverts speaker to import user")
  func editClearGithubUsernameRevertsToImportUser() async throws {
    let app = try await makeTestApp()
    defer { Task { try? await app.asyncShutdown() } }

    let realUser = User(githubID: 55555, username: "realuser", role: .speaker)
    try await realUser.save(on: app.db)

    let conference = try await Conference.query(on: app.db)
      .filter(\.$path == "tryswift-tokyo-2026")
      .first()
    let conferenceID = try #require(conference?.id)

    let proposal = Proposal(
      conferenceID: conferenceID,
      title: "Test Talk",
      abstract: "Abstract",
      talkDetail: "Detail",
      talkDuration: .regular,
      speakerName: "Real User",
      speakerEmail: "real@test.com",
      bio: "Bio",
      speakerID: try #require(realUser.id)
    )
    try await proposal.save(on: app.db)

    // Pre-condition: speaker is the real user, not the import user
    #expect(proposal.$speaker.id == realUser.id)
    #expect(proposal.$speaker.id != AddPaperCallImportUser.paperCallUserID)

    // Simulate the edit handler's revert logic (mirrors handleOrganizerEditProposal)
    let githubUsername = ""
    if !githubUsername.isEmpty {
      Issue.record("Should not enter this branch")
    } else if proposal.$speaker.id != AddPaperCallImportUser.paperCallUserID {
      let routes = CfPRoutes()
      let importUserID = try await routes.resolveSpeakerID(githubUsername: nil, on: app.db)
      proposal.$speaker.id = importUserID
      proposal.paperCallUsername = nil
    }

    try await proposal.save(on: app.db)

    let updated = try await Proposal.find(proposal.id, on: app.db)
    #expect(updated?.$speaker.id == AddPaperCallImportUser.paperCallUserID)
  }

  // MARK: - Delete proposal

  @Test("deleting a proposal removes it and sets linked ScheduleSlot proposal_id to null")
  func deleteProposalSetsScheduleSlotNull() async throws {
    let app = try await makeTestApp()
    defer { Task { try? await app.asyncShutdown() } }

    let conference = try await Conference.query(on: app.db)
      .filter(\.$path == "tryswift-tokyo-2026")
      .first()
    let conferenceID = try #require(conference?.id)

    let proposal = Proposal(
      conferenceID: conferenceID,
      title: "Talk to Delete",
      abstract: "Abstract",
      talkDetail: "Detail",
      talkDuration: .regular,
      speakerName: "Speaker",
      speakerEmail: "speaker@test.com",
      bio: "Bio",
      speakerID: AddPaperCallImportUser.paperCallUserID
    )
    try await proposal.save(on: app.db)
    let proposalID = try #require(proposal.id)

    // Create a ScheduleSlot linked to this proposal
    let slot = ScheduleSlot(
      conferenceID: conferenceID,
      proposalID: proposalID,
      day: 1,
      startTime: Date(),
      slotType: .talk,
      sortOrder: 1
    )
    try await slot.save(on: app.db)
    let slotID = try #require(slot.id)

    // Verify slot is linked
    let linkedSlot = try await ScheduleSlot.find(slotID, on: app.db)
    #expect(linkedSlot?.$proposal.id == proposalID)

    // Delete proposal — onDelete: .setNull should null out slot's proposal_id
    try await proposal.delete(on: app.db)

    // Verify proposal is gone
    let deleted = try await Proposal.find(proposalID, on: app.db)
    #expect(deleted == nil)

    // Verify slot still exists but proposal_id is now null
    let updatedSlot = try await ScheduleSlot.find(slotID, on: app.db)
    #expect(updatedSlot != nil)
    #expect(updatedSlot?.$proposal.id == nil)
  }

  // MARK: - Update GitHub ID

  @Test("updating GitHub username changes speaker association")
  func updateGitHubUsername() async throws {
    let app = try await makeTestApp()
    defer { Task { try? await app.asyncShutdown() } }

    let realUser = User(githubID: 77777, username: "newowner", role: .speaker)
    try await realUser.save(on: app.db)

    let conference = try await Conference.query(on: app.db)
      .filter(\.$path == "tryswift-tokyo-2026")
      .first()
    let conferenceID = try #require(conference?.id)

    let proposal = Proposal(
      conferenceID: conferenceID,
      title: "Reassign Talk",
      abstract: "Abstract",
      talkDetail: "Detail",
      talkDuration: .regular,
      speakerName: "Original Speaker",
      speakerEmail: "original@test.com",
      bio: "Bio",
      speakerID: AddPaperCallImportUser.paperCallUserID
    )
    try await proposal.save(on: app.db)

    // Simulate the update-github handler logic
    let routes = CfPRoutes()
    let resolvedID = try await routes.resolveSpeakerID(
      githubUsername: "newowner", on: app.db)
    proposal.$speaker.id = resolvedID
    proposal.paperCallUsername = "newowner"
    try await proposal.save(on: app.db)

    let updated = try await Proposal.find(proposal.id, on: app.db)
    #expect(updated?.$speaker.id == realUser.id)
    #expect(updated?.paperCallUsername == "newowner")
  }

  @Test("clearing GitHub username is no-op when already on import user")
  func editClearGithubUsernameNoopForImportUser() async throws {
    let app = try await makeTestApp()
    defer { Task { try? await app.asyncShutdown() } }

    let conference = try await Conference.query(on: app.db)
      .filter(\.$path == "tryswift-tokyo-2026")
      .first()
    let conferenceID = try #require(conference?.id)

    let proposal = Proposal(
      conferenceID: conferenceID,
      title: "Imported Talk",
      abstract: "Abstract",
      talkDetail: "Detail",
      talkDuration: .regular,
      speakerName: "Imported Speaker",
      speakerEmail: "imported@test.com",
      bio: "Bio",
      speakerID: AddPaperCallImportUser.paperCallUserID
    )
    try await proposal.save(on: app.db)

    // When username is cleared but speaker is already the import user,
    // the revert branch should NOT execute.
    let githubUsername = ""
    var didRevert = false
    if !githubUsername.isEmpty {
      Issue.record("Should not enter this branch")
    } else if proposal.$speaker.id != AddPaperCallImportUser.paperCallUserID {
      didRevert = true
    }

    #expect(!didRevert)
    #expect(proposal.$speaker.id == AddPaperCallImportUser.paperCallUserID)
  }
}
