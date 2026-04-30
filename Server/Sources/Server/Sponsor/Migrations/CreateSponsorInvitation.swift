import Fluent

struct CreateSponsorInvitation: AsyncMigration {
  func prepare(on database: Database) async throws {
    try await database.schema(SponsorInvitation.schema)
      .id()
      .field(
        "organization_id", .uuid, .required,
        .references(SponsorOrganization.schema, "id", onDelete: .cascade)
      )
      .field("email", .string, .required)
      .field("role", .string, .required)
      .field("token_hash", .string, .required)
      .field("expires_at", .datetime, .required)
      .field("accepted_at", .datetime)
      .field("invited_by_sponsor_user_id", .uuid, .required)
      .field("created_at", .datetime)
      .unique(on: "token_hash")
      .create()
  }

  func revert(on database: Database) async throws {
    try await database.schema(SponsorInvitation.schema).delete()
  }
}
