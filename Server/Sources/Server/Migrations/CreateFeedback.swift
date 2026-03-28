import Fluent

/// Migration to create feedbacks table
struct CreateFeedback: AsyncMigration {
  func prepare(on database: Database) async throws {
    try await database.schema(Feedback.schema)
      .id()
      .field(
        "proposal_id", .uuid, .required,
        .references(Proposal.schema, "id", onDelete: .cascade)
      )
      .field("comment", .string, .required)
      .field("device_id", .string)
      .field("created_at", .datetime)
      .create()
  }

  func revert(on database: Database) async throws {
    try await database.schema(Feedback.schema).delete()
  }
}
