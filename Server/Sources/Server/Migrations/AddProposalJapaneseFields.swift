import Fluent

struct AddProposalJapaneseFields: AsyncMigration {
  func prepare(on database: Database) async throws {
    try await database.schema(Proposal.schema)
      .field("title_ja", .string)
      .field("abstract_ja", .string)
      .update()
  }

  func revert(on database: Database) async throws {
    try await database.schema(Proposal.schema)
      .deleteField("title_ja")
      .deleteField("abstract_ja")
      .update()
  }
}
