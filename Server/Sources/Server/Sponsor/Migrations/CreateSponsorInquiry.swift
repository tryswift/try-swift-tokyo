import Fluent

struct CreateSponsorInquiry: AsyncMigration {
  func prepare(on database: Database) async throws {
    try await database.schema(SponsorInquiry.schema)
      .id()
      .field(
        "conference_id", .uuid, .required,
        .references(Conference.schema, "id", onDelete: .cascade)
      )
      .field("company_name", .string, .required)
      .field("contact_name", .string, .required)
      .field("email", .string, .required)
      .field("desired_plan_slug", .string)
      .field("message", .string, .required)
      .field("locale", .string, .required)
      .field("status", .string, .required)
      .field("created_at", .datetime)
      .create()
  }

  func revert(on database: Database) async throws {
    try await database.schema(SponsorInquiry.schema).delete()
  }
}
