import Fluent

struct AddIsAcceptingSponsorsToConference: AsyncMigration {
  func prepare(on database: Database) async throws {
    try await database.schema(Conference.schema)
      .field("is_accepting_sponsors", .bool, .required, .sql(.default(false)))
      .update()
  }

  func revert(on database: Database) async throws {
    try await database.schema(Conference.schema)
      .deleteField("is_accepting_sponsors")
      .update()
  }
}
