import Fluent

struct CreateSponsorMembership: AsyncMigration {
  func prepare(on database: Database) async throws {
    try await database.schema(SponsorMembership.schema)
      .id()
      .field(
        "organization_id", .uuid, .required,
        .references(SponsorOrganization.schema, "id", onDelete: .cascade)
      )
      .field(
        "sponsor_user_id", .uuid, .required,
        .references(SponsorUser.schema, "id", onDelete: .cascade)
      )
      .field("role", .string, .required)
      .field("invited_by_sponsor_user_id", .uuid)
      .field("created_at", .datetime)
      .unique(on: "organization_id", "sponsor_user_id")
      .create()
  }

  func revert(on database: Database) async throws {
    try await database.schema(SponsorMembership.schema).delete()
  }
}
