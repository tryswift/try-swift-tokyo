import Fluent

/// Migration to add github_username field to proposals table
struct AddProposalGitHubUsername: AsyncMigration {
  func prepare(on database: Database) async throws {
    try await database.schema(Proposal.schema)
      .field("github_username", .string)
      .update()
  }

  func revert(on database: Database) async throws {
    try await database.schema(Proposal.schema)
      .deleteField("github_username")
      .update()
  }
}
