import Fluent
import FluentSQLiteDriver
import JWT
import Testing
import Vapor
import VaporTesting

@testable import Server

/// Schema migration that creates only the user and conference tables for the
/// ConferenceController tests.
private struct CreateConferenceAPITestSchema: AsyncMigration {
  var name: String { "CreateConferenceAPITestSchema" }

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
      .field("is_published", .bool, .required, .sql(.default(true)))
      .field("deadline", .datetime)
      .field("start_date", .datetime)
      .field("end_date", .datetime)
      .field("location", .string)
      .field("website_url", .string)
      .field("created_at", .datetime)
      .field("updated_at", .datetime)
      .create()
  }

  func revert(on database: Database) async throws {
    try await database.schema(Conference.schema).delete()
    try await database.schema(User.schema).delete()
  }
}

@Suite("Conference API Tests")
struct ConferenceAPITests {
  private let jwtSecret = "conference-api-test-secret"

  private func makeApp() async throws -> Application {
    let app = try await Application.make(.testing)
    app.databases.use(.sqlite(.memory), as: .sqlite)
    app.migrations.add(CreateConferenceAPITestSchema())
    try await app.autoMigrate()
    await app.jwt.keys.add(hmac: HMACKey(from: jwtSecret), digestAlgorithm: .sha256)

    let api = app.grouped("api", "v1")
    try api.register(collection: ConferenceController())

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

  private func seedConferences(on db: Database) async throws {
    try await Conference(
      path: "published-open",
      displayName: "Published Open",
      year: 2027,
      isOpen: true,
      isPublished: true
    ).save(on: db)

    try await Conference(
      path: "published-closed",
      displayName: "Published Closed",
      year: 2025,
      isOpen: false,
      isPublished: true
    ).save(on: db)

    try await Conference(
      path: "draft-open",
      displayName: "Draft Open",
      year: 2028,
      isOpen: true,
      isPublished: false
    ).save(on: db)
  }

  @Test("GET /conferences excludes unpublished drafts")
  func publicListExcludesUnpublished() async throws {
    try await withTestApp { app in
      try await seedConferences(on: app.db)

      try await app.testing().test(.GET, "api/v1/conferences") { res in
        #expect(res.status == .ok)
        let body = try res.content.decode([ConferenceDTOContent].self)
        let paths = body.map(\.path).sorted()
        #expect(paths == ["published-closed", "published-open"])
      }
    }
  }

  @Test("GET /conferences/open requires both isOpen and isPublished")
  func publicOpenListRequiresPublished() async throws {
    try await withTestApp { app in
      try await seedConferences(on: app.db)

      try await app.testing().test(.GET, "api/v1/conferences/open") { res in
        #expect(res.status == .ok)
        let body = try res.content.decode([ConferenceDTOContent].self)
        let paths = body.map(\.path)
        #expect(paths == ["published-open"])
      }
    }
  }

  @Test("GET /conferences/:path returns 404 for unpublished conferences")
  func publicLookupHidesDrafts() async throws {
    try await withTestApp { app in
      try await seedConferences(on: app.db)

      try await app.testing().test(.GET, "api/v1/conferences/draft-open") { res in
        #expect(res.status == .notFound)
      }

      try await app.testing().test(.GET, "api/v1/conferences/published-open") { res in
        #expect(res.status == .ok)
        let body = try res.content.decode(ConferenceDTOContent.self)
        #expect(body.path == "published-open")
        #expect(body.isPublished == true)
      }
    }
  }

  @Test("GET /conferences/admin/all returns every conference for organizers")
  func adminListReturnsAll() async throws {
    try await withTestApp { app in
      try await seedConferences(on: app.db)

      let admin = User(githubID: 1, username: "organizer", role: .admin)
      try await admin.save(on: app.db)
      let token = try await makeToken(for: admin, on: app)

      try await app.testing().test(
        .GET, "api/v1/conferences/admin/all",
        beforeRequest: { req in
          req.headers.bearerAuthorization = .init(token: token)
        }
      ) { res in
        #expect(res.status == .ok)
        let body = try res.content.decode([ConferenceDTOContent].self)
        let paths = body.map(\.path).sorted()
        #expect(paths == ["draft-open", "published-closed", "published-open"])
      }
    }
  }

  @Test("GET /conferences/admin/all rejects non-admin callers")
  func adminListRejectsNonAdmin() async throws {
    try await withTestApp { app in
      try await seedConferences(on: app.db)

      let speaker = User(githubID: 2, username: "speaker", role: .speaker)
      try await speaker.save(on: app.db)
      let token = try await makeToken(for: speaker, on: app)

      try await app.testing().test(
        .GET, "api/v1/conferences/admin/all",
        beforeRequest: { req in
          req.headers.bearerAuthorization = .init(token: token)
        }
      ) { res in
        #expect(res.status == .forbidden)
      }
    }
  }
}
