import Fluent

struct CreateScholarshipBudget: AsyncMigration {
  func prepare(on database: Database) async throws {
    try await database.schema(ScholarshipBudget.schema)
      .id()
      .field(
        "conference_id", .uuid, .required,
        .references(Conference.schema, "id", onDelete: .cascade)
      )
      .field("total_budget", .int, .required)
      .field("notes", .string)
      .field("created_at", .datetime)
      .field("updated_at", .datetime)
      .unique(on: "conference_id")
      .create()
  }

  func revert(on database: Database) async throws {
    try await database.schema(ScholarshipBudget.schema).delete()
  }
}
