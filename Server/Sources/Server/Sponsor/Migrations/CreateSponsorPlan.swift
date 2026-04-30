import Fluent

struct CreateSponsorPlan: AsyncMigration {
  func prepare(on database: Database) async throws {
    try await database.schema(SponsorPlan.schema)
      .id()
      .field(
        "conference_id", .uuid, .required, .references(Conference.schema, "id", onDelete: .cascade)
      )
      .field("slug", .string, .required)
      .field("sort_order", .int, .required)
      .field("price_jpy", .int, .required)
      .field("capacity", .int)
      .field("deadline_at", .datetime)
      .field("is_active", .bool, .required, .sql(.default(true)))
      .field("created_at", .datetime)
      .field("updated_at", .datetime)
      .unique(on: "conference_id", "slug")
      .create()
  }

  func revert(on database: Database) async throws {
    try await database.schema(SponsorPlan.schema).delete()
  }
}
