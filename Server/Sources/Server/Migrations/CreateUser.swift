import Fluent
import SharedModels

/// Migration to create the users table
struct CreateUser: AsyncMigration {
  func prepare(on database: Database) async throws {
    try await database.schema(User.schema)
      .id()
      .field("github_id", .int, .required)
      .field("username", .string, .required)
      .field("role", .string, .required)
      .field("display_name", .string)
      .field("bio", .string)
      .field("url", .string)
      .field("organization", .string)
      .field("avatar_url", .string)
      .field("created_at", .datetime)
      .field("updated_at", .datetime)
      .unique(on: "github_id")
      .create()
  }

  func revert(on database: Database) async throws {
    try await database.schema(User.schema).delete()
  }
}
