import Fluent

/// Migration to create favorites table
struct CreateFavorite: AsyncMigration {
  func prepare(on database: Database) async throws {
    try await database.schema(Favorite.schema)
      .id()
      .field(
        "proposal_id", .uuid, .required,
        .references(Proposal.schema, "id", onDelete: .cascade)
      )
      .field("device_id", .string, .required)
      .field("created_at", .datetime)
      .unique(on: "proposal_id", "device_id")
      .create()
  }

  func revert(on database: Database) async throws {
    try await database.schema(Favorite.schema).delete()
  }
}
