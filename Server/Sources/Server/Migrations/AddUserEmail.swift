import Fluent

/// Migration to add email field to users table
struct AddUserEmail: AsyncMigration {
  func prepare(on database: Database) async throws {
    try await database.schema(User.schema)
      .field("email", .string)
      .update()
  }

  func revert(on database: Database) async throws {
    try await database.schema(User.schema)
      .deleteField("email")
      .update()
  }
}
