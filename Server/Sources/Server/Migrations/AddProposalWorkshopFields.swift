import Fluent

struct AddProposalWorkshopFields: AsyncMigration {
  func prepare(on database: Database) async throws {
    try await database.schema(Proposal.schema)
      .field("workshop_details", .json)
      .field("co_instructors", .json)
      .update()
  }

  func revert(on database: Database) async throws {
    try await database.schema(Proposal.schema)
      .deleteField("workshop_details")
      .deleteField("co_instructors")
      .update()
  }
}
