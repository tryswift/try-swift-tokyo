import Fluent
import FluentSQLiteDriver
import Foundation
import Testing
import Vapor
import VaporTesting

@testable import Server

/// SQLite-compatible migration that creates all tables needed for Favorites & Feedback tests.
/// SQLite doesn't support ALTER TABLE well, so we create the final schema directly.
private struct CreateFavoritesTestSchema: AsyncMigration {
  var name: String { "CreateFavoritesTestSchema" }

  func prepare(on database: Database) async throws {
    // Users table
    try await database.schema("users")
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

    // Conferences table
    try await database.schema("conferences")
      .id()
      .field("path", .string, .required)
      .field("display_name", .string, .required)
      .field("description_en", .string)
      .field("description_ja", .string)
      .field("year", .int, .required)
      .field("is_open", .bool, .required)
      .field("is_accepting_sponsors", .bool, .required, .sql(.default(false)))
      .field("is_published", .bool, .required, .sql(.default(true)))
      .field("deadline", .datetime)
      .field("start_date", .datetime)
      .field("end_date", .datetime)
      .field("location", .string)
      .field("website_url", .string)
      .field("created_at", .datetime)
      .field("updated_at", .datetime)
      .create()

    // Proposals table
    try await database.schema("proposals")
      .id()
      .field("conference_id", .uuid, .required, .references("conferences", "id"))
      .field("title", .string, .required)
      .field("abstract", .string, .required)
      .field("talk_detail", .string, .required)
      .field("talk_duration", .string, .required)
      .field("bio", .string, .required)
      .field("icon_url", .string)
      .field("notes", .string)
      .field("speaker_id", .uuid, .required, .references("users", "id"))
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

    // Favorites table
    try await database.schema("favorites")
      .id()
      .field("proposal_id", .uuid, .required, .references("proposals", "id", onDelete: .cascade))
      .field("device_id", .string, .required)
      .field("created_at", .datetime)
      .unique(on: "proposal_id", "device_id")
      .create()

    // Feedbacks table
    try await database.schema("feedbacks")
      .id()
      .field("proposal_id", .uuid, .required, .references("proposals", "id", onDelete: .cascade))
      .field("comment", .string, .required)
      .field("device_id", .string)
      .field("created_at", .datetime)
      .create()
  }

  func revert(on database: Database) async throws {
    try await database.schema("feedbacks").delete()
    try await database.schema("favorites").delete()
    try await database.schema("proposals").delete()
    try await database.schema("conferences").delete()
    try await database.schema("users").delete()
  }
}

@Suite("Favorites and Feedback Tests")
struct FavoritesAndFeedbackTests {

  /// Create a Vapor Application backed by in-memory SQLite with all required tables
  /// and the Favorites/Feedback controllers registered.
  private func makeTestApp() async throws -> Application {
    let app = try await Application.make(.testing)
    app.databases.use(.sqlite(.memory), as: .sqlite)
    app.migrations.add(CreateFavoritesTestSchema())
    try await app.autoMigrate()

    // Register the controllers under /api/v1
    let api = app.grouped("api", "v1")
    try api.register(collection: FavoritesController())
    try api.register(collection: FeedbackController())

    return app
  }

  private func withTestApp(_ body: (Application) async throws -> Void) async throws {
    let app = try await makeTestApp()
    do {
      try await body(app)
    } catch {
      try await app.asyncShutdown()
      throw error
    }
    try await app.asyncShutdown()
  }

  /// Seed a user, conference, and proposal for testing. Returns the created models.
  private func seedProposal(on db: Database) async throws -> (
    user: User, conference: Conference, proposal: Proposal
  ) {
    let user = User(githubID: 12345, username: "testuser", role: .speaker)
    try await user.save(on: db)

    let conference = Conference(
      path: "test-2026", displayName: "Test Conference", year: 2026, isOpen: true)
    try await conference.save(on: db)

    let proposal = Proposal(
      conferenceID: try conference.requireID(),
      title: "Test Talk",
      abstract: "A test abstract",
      talkDetail: "Detailed talk info",
      talkDuration: .regular,
      speakerName: "Test Speaker",
      speakerEmail: "test@example.com",
      bio: "A test bio",
      speakerID: try user.requireID(),
      status: .accepted
    )
    try await proposal.save(on: db)

    return (user, conference, proposal)
  }

  // MARK: - FavoritesController Tests

  @Test("toggleFavorite adds a new favorite")
  func toggleFavorite_addsNewFavorite() async throws {
    try await withTestApp { app in
      let (_, _, proposal) = try await seedProposal(on: app.db)
      let proposalId = try proposal.requireID()

      try await app.testing().test(
        .PUT, "api/v1/favorites",
        beforeRequest: { req in
          try req.content.encode(FavoriteToggleRequest(proposalId: proposalId, deviceId: "device1"))
        },
        afterResponse: { response in
          #expect(response.status == .ok)
          let body = try response.content.decode(FavoriteToggleResponse.self)
          #expect(body.isFavorite == true)
          #expect(body.count == 1)
        }
      )
    }
  }

  @Test("toggleFavorite removes an existing favorite")
  func toggleFavorite_removesFavorite() async throws {
    try await withTestApp { app in
      let (_, _, proposal) = try await seedProposal(on: app.db)
      let proposalId = try proposal.requireID()

      // Add a favorite first
      let favorite = Favorite(proposalID: proposalId, deviceID: "device1")
      try await favorite.save(on: app.db)

      // Toggle should remove it
      try await app.testing().test(
        .PUT, "api/v1/favorites",
        beforeRequest: { req in
          try req.content.encode(FavoriteToggleRequest(proposalId: proposalId, deviceId: "device1"))
        },
        afterResponse: { response in
          #expect(response.status == .ok)
          let body = try response.content.decode(FavoriteToggleResponse.self)
          #expect(body.isFavorite == false)
          #expect(body.count == 0)
        }
      )
    }
  }

  @Test("toggleFavorite rejects empty deviceId")
  func toggleFavorite_rejectsEmptyDeviceId() async throws {
    try await withTestApp { app in
      let (_, _, proposal) = try await seedProposal(on: app.db)
      let proposalId = try proposal.requireID()

      try await app.testing().test(
        .PUT, "api/v1/favorites",
        beforeRequest: { req in
          try req.content.encode(FavoriteToggleRequest(proposalId: proposalId, deviceId: ""))
        },
        afterResponse: { response in
          #expect(response.status == .badRequest)
        }
      )
    }
  }

  @Test("toggleFavorite rejects non-existent proposal")
  func toggleFavorite_rejectsInvalidProposal() async throws {
    try await withTestApp { app in
      let nonExistentId = UUID()

      try await app.testing().test(
        .PUT, "api/v1/favorites",
        beforeRequest: { req in
          try req.content.encode(
            FavoriteToggleRequest(proposalId: nonExistentId, deviceId: "device1"))
        },
        afterResponse: { response in
          #expect(response.status == .notFound)
        }
      )
    }
  }

  @Test("getFavorites returns user favorites for a given deviceId")
  func getFavorites_returnsUserFavorites() async throws {
    try await withTestApp { app in
      let (user, conference, proposal1) = try await seedProposal(on: app.db)
      let proposal1Id = try proposal1.requireID()

      // Create a second proposal
      let proposal2 = Proposal(
        conferenceID: try conference.requireID(),
        title: "Second Talk",
        abstract: "Another abstract",
        talkDetail: "More detail",
        talkDuration: .lightning,
        speakerName: "Test Speaker",
        speakerEmail: "test@example.com",
        bio: "A test bio",
        speakerID: try user.requireID(),
        status: .accepted
      )
      try await proposal2.save(on: app.db)
      let proposal2Id = try proposal2.requireID()

      // Add favorites for device1
      try await Favorite(proposalID: proposal1Id, deviceID: "device1").save(on: app.db)
      try await Favorite(proposalID: proposal2Id, deviceID: "device1").save(on: app.db)

      // Add a favorite for a different device (should not appear)
      try await Favorite(proposalID: proposal1Id, deviceID: "device2").save(on: app.db)

      try await app.testing().test(
        .GET, "api/v1/favorites?deviceId=device1",
        afterResponse: { response in
          #expect(response.status == .ok)
          let items = try response.content.decode([FavoriteItem].self)
          #expect(items.count == 2)
          let returnedIds = Set(items.map(\.proposalId))
          #expect(returnedIds.contains(proposal1Id))
          #expect(returnedIds.contains(proposal2Id))
        }
      )
    }
  }

  @Test("getFavoriteCounts returns aggregated counts per proposal")
  func getFavoriteCounts_returnsAggregatedCounts() async throws {
    try await withTestApp { app in
      let (user, conference, proposal1) = try await seedProposal(on: app.db)
      let proposal1Id = try proposal1.requireID()

      // Create a second proposal
      let proposal2 = Proposal(
        conferenceID: try conference.requireID(),
        title: "Second Talk",
        abstract: "Another abstract",
        talkDetail: "More detail",
        talkDuration: .lightning,
        speakerName: "Test Speaker",
        speakerEmail: "test@example.com",
        bio: "A test bio",
        speakerID: try user.requireID(),
        status: .accepted
      )
      try await proposal2.save(on: app.db)
      let proposal2Id = try proposal2.requireID()

      // Proposal 1 gets 3 favorites from different devices
      try await Favorite(proposalID: proposal1Id, deviceID: "device1").save(on: app.db)
      try await Favorite(proposalID: proposal1Id, deviceID: "device2").save(on: app.db)
      try await Favorite(proposalID: proposal1Id, deviceID: "device3").save(on: app.db)

      // Proposal 2 gets 1 favorite
      try await Favorite(proposalID: proposal2Id, deviceID: "device1").save(on: app.db)

      try await app.testing().test(
        .GET, "api/v1/favorite-counts",
        afterResponse: { response in
          #expect(response.status == .ok)
          let counts = try response.content.decode([FavoriteCountItem].self)
          #expect(counts.count == 2)

          let countMap = Dictionary(uniqueKeysWithValues: counts.map { ($0.proposalId, $0.count) })
          #expect(countMap[proposal1Id] == 3)
          #expect(countMap[proposal2Id] == 1)
        }
      )
    }
  }

  // MARK: - FeedbackController Tests

  @Test("submitFeedback succeeds with valid data")
  func submitFeedback_success() async throws {
    try await withTestApp { app in
      let (_, _, proposal) = try await seedProposal(on: app.db)
      let proposalId = try proposal.requireID()

      try await app.testing().test(
        .POST, "api/v1/feedback",
        beforeRequest: { req in
          try req.content.encode(
            FeedbackSubmission(proposalId: proposalId, comment: "Great talk!", deviceId: "device1"))
        },
        afterResponse: { response in
          #expect(response.status == .created)
        }
      )

      // Verify the feedback was persisted
      let feedbacks = try await Feedback.query(on: app.db).all()
      #expect(feedbacks.count == 1)
      #expect(feedbacks.first?.comment == "Great talk!")
    }
  }

  @Test("submitFeedback rejects empty comment")
  func submitFeedback_rejectsEmptyComment() async throws {
    try await withTestApp { app in
      let (_, _, proposal) = try await seedProposal(on: app.db)
      let proposalId = try proposal.requireID()

      try await app.testing().test(
        .POST, "api/v1/feedback",
        beforeRequest: { req in
          try req.content.encode(
            FeedbackSubmission(proposalId: proposalId, comment: "", deviceId: "device1"))
        },
        afterResponse: { response in
          #expect(response.status == .badRequest)
        }
      )
    }
  }

  @Test("submitFeedback rejects comment over 2000 characters")
  func submitFeedback_rejectsLongComment() async throws {
    try await withTestApp { app in
      let (_, _, proposal) = try await seedProposal(on: app.db)
      let proposalId = try proposal.requireID()

      let longComment = String(repeating: "a", count: 2001)

      try await app.testing().test(
        .POST, "api/v1/feedback",
        beforeRequest: { req in
          try req.content.encode(
            FeedbackSubmission(proposalId: proposalId, comment: longComment, deviceId: "device1"))
        },
        afterResponse: { response in
          #expect(response.status == .badRequest)
        }
      )
    }
  }

  @Test("submitFeedback rate limits at 3 per device per proposal")
  func submitFeedback_rateLimits() async throws {
    try await withTestApp { app in
      let (_, _, proposal) = try await seedProposal(on: app.db)
      let proposalId = try proposal.requireID()

      // Submit 3 feedbacks (should all succeed)
      for i in 1...3 {
        try await app.testing().test(
          .POST, "api/v1/feedback",
          beforeRequest: { req in
            try req.content.encode(
              FeedbackSubmission(
                proposalId: proposalId, comment: "Feedback \(i)", deviceId: "device1"))
          },
          afterResponse: { response in
            #expect(response.status == .created)
          }
        )
      }

      // 4th feedback should be rate limited
      try await app.testing().test(
        .POST, "api/v1/feedback",
        beforeRequest: { req in
          try req.content.encode(
            FeedbackSubmission(proposalId: proposalId, comment: "One too many", deviceId: "device1")
          )
        },
        afterResponse: { response in
          #expect(response.status == .tooManyRequests)
        }
      )
    }
  }
}
