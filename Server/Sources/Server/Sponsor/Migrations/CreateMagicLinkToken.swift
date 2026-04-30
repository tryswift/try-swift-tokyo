import Fluent

struct CreateMagicLinkToken: AsyncMigration {
  func prepare(on database: Database) async throws {
    try await database.schema(MagicLinkToken.schema)
      .id()
      .field(
        "sponsor_user_id", .uuid, .required,
        .references(SponsorUser.schema, "id", onDelete: .cascade)
      )
      .field("token_hash", .string, .required)
      .field("purpose", .string, .required)
      .field("expires_at", .datetime, .required)
      .field("used_at", .datetime)
      .field("created_at", .datetime)
      .unique(on: "token_hash")
      .create()
  }

  func revert(on database: Database) async throws {
    try await database.schema(MagicLinkToken.schema).delete()
  }
}
