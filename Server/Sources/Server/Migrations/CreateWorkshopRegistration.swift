import Fluent

/// Migration to create workshop_registrations table
struct CreateWorkshopRegistration: AsyncMigration {
  func prepare(on database: Database) async throws {
    try await database.schema(WorkshopRegistration.schema)
      .id()
      .field(
        "proposal_id", .uuid, .required,
        .references(Proposal.schema, "id", onDelete: .cascade)
      )
      .field("capacity", .int, .required)
      .field("luma_event_id", .string)
      .field("created_at", .datetime)
      .field("updated_at", .datetime)
      .unique(on: "proposal_id")
      .create()
  }

  func revert(on database: Database) async throws {
    try await database.schema(WorkshopRegistration.schema).delete()
  }
}
