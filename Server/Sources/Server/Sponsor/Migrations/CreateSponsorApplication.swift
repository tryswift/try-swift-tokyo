import Fluent

struct CreateSponsorApplication: AsyncMigration {
  func prepare(on database: Database) async throws {
    try await database.schema(SponsorApplication.schema)
      .id()
      .field(
        "organization_id", .uuid, .required,
        .references(SponsorOrganization.schema, "id", onDelete: .cascade)
      )
      .field("plan_id", .uuid, .required, .references(SponsorPlan.schema, "id"))
      .field("conference_id", .uuid, .required, .references(Conference.schema, "id"))
      .field("status", .string, .required)
      .field("payload", .json, .required)
      .field("submitted_at", .datetime)
      .field("decided_at", .datetime)
      .field("decided_by_user_id", .uuid)
      .field("decision_note", .string)
      .field("created_at", .datetime)
      .field("updated_at", .datetime)
      .create()
  }

  func revert(on database: Database) async throws {
    try await database.schema(SponsorApplication.schema).delete()
  }
}
