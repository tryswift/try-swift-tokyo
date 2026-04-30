import Fluent

struct CreateSponsorOrganization: AsyncMigration {
  func prepare(on database: Database) async throws {
    try await database.schema(SponsorOrganization.schema)
      .id()
      .field("legal_name", .string, .required)
      .field("display_name", .string, .required)
      .field("country", .string)
      .field("billing_address", .string)
      .field("website_url", .string)
      .field("status", .string, .required)
      .field("created_at", .datetime)
      .field("updated_at", .datetime)
      .create()
  }

  func revert(on database: Database) async throws {
    try await database.schema(SponsorOrganization.schema).delete()
  }
}
