import Fluent

/// Migration to add bio_ja, job_title, and job_title_ja fields to proposals table
struct AddProposalSpeakerDetails: AsyncMigration {
  func prepare(on database: Database) async throws {
    try await database.schema(Proposal.schema)
      .field("bio_ja", .string)
      .field("job_title", .string)
      .field("job_title_ja", .string)
      .update()
  }

  func revert(on database: Database) async throws {
    try await database.schema(Proposal.schema)
      .deleteField("bio_ja")
      .deleteField("job_title")
      .deleteField("job_title_ja")
      .update()
  }
}
