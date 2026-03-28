import Fluent

struct AddProposalWorkshopDetailsJA: AsyncMigration {
  func prepare(on database: Database) async throws {
    try await database.schema(Proposal.schema)
      .field("workshop_details_ja", .json)
      .update()
  }

  func revert(on database: Database) async throws {
    try await database.schema(Proposal.schema)
      .deleteField("workshop_details_ja")
      .update()
  }
}
