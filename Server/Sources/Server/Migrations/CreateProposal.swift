import Fluent

/// Migration to create the proposals table
struct CreateProposal: AsyncMigration {
  func prepare(on database: Database) async throws {
    try await database.schema(Proposal.schema)
      .id()
      .field(
        "conference_id", .uuid, .required, .references(Conference.schema, "id", onDelete: .cascade)
      )
      .field("title", .string, .required)
      .field("abstract", .string, .required)
      .field("talk_detail", .string, .required)
      .field("talk_duration", .string, .required)
      .field("bio", .string, .required)
      .field("icon_url", .string)
      .field("notes", .string)
      .field("speaker_id", .uuid, .required, .references(User.schema, "id", onDelete: .cascade))
      .field("created_at", .datetime)
      .field("updated_at", .datetime)
      .create()
  }

  func revert(on database: Database) async throws {
    try await database.schema(Proposal.schema).delete()
  }
}
