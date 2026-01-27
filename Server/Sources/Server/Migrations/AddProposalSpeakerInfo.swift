import Fluent

/// Migration to add speaker_name and speaker_email fields to proposals table
struct AddProposalSpeakerInfo: AsyncMigration {
  func prepare(on database: Database) async throws {
    try await database.schema(Proposal.schema)
      .field("speaker_name", .string, .required, .sql(.default("")))
      .field("speaker_email", .string, .required, .sql(.default("")))
      .update()
  }

  func revert(on database: Database) async throws {
    try await database.schema(Proposal.schema)
      .deleteField("speaker_name")
      .deleteField("speaker_email")
      .update()
  }
}
