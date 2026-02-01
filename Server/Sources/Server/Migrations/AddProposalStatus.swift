import Fluent

/// Migration to add status field to proposals table
struct AddProposalStatus: AsyncMigration {
  func prepare(on database: Database) async throws {
    try await database.schema(Proposal.schema)
      .field("status", .string, .required, .sql(.default("submitted")))
      .update()
  }

  func revert(on database: Database) async throws {
    try await database.schema(Proposal.schema)
      .deleteField("status")
      .update()
  }
}
