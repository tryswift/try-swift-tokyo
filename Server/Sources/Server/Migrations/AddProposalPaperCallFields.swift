import Fluent

/// Migration to add PaperCall-specific fields to proposals table
/// These fields store metadata from PaperCall imports
struct AddProposalPaperCallFields: AsyncMigration {
  func prepare(on database: Database) async throws {
    try await database.schema(Proposal.schema)
      .field("papercall_id", .string)
      .field("papercall_username", .string)
      .update()
  }

  func revert(on database: Database) async throws {
    try await database.schema(Proposal.schema)
      .deleteField("papercall_id")
      .deleteField("papercall_username")
      .update()
  }
}
