import Fluent

struct CreateSponsorUser: AsyncMigration {
  func prepare(on database: Database) async throws {
    try await database.schema(SponsorUser.schema)
      .id()
      .field("email", .string, .required)
      .field("display_name", .string)
      .field("locale", .string, .required)
      .field("created_at", .datetime)
      .field("updated_at", .datetime)
      .unique(on: "email")
      .create()
  }

  func revert(on database: Database) async throws {
    try await database.schema(SponsorUser.schema).delete()
  }
}
