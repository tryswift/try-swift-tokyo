import Fluent

struct CreateSponsorPlanLocalization: AsyncMigration {
  func prepare(on database: Database) async throws {
    try await database.schema(SponsorPlanLocalization.schema)
      .id()
      .field("plan_id", .uuid, .required, .references(SponsorPlan.schema, "id", onDelete: .cascade))
      .field("locale", .string, .required)
      .field("name", .string, .required)
      .field("summary", .string, .required)
      .field("benefits", .array(of: .string), .required)
      .unique(on: "plan_id", "locale")
      .create()
  }

  func revert(on database: Database) async throws {
    try await database.schema(SponsorPlanLocalization.schema).delete()
  }
}
