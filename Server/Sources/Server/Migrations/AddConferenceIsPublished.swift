import Fluent

/// Migration to add is_published flag to conferences table.
struct AddConferenceIsPublished: AsyncMigration {
  func prepare(on database: Database) async throws {
    try await database.schema(Conference.schema)
      .field("is_published", .bool, .required, .sql(.default(true)))
      .update()
  }

  func revert(on database: Database) async throws {
    try await database.schema(Conference.schema)
      .deleteField("is_published")
      .update()
  }
}
