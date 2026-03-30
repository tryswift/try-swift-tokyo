import Fluent
import SQLKit

/// Migration to add indexes to feedbacks table
struct AddFeedbackIndexes: AsyncMigration {
  func prepare(on database: Database) async throws {
    guard let sql = database as? SQLDatabase else { return }
    try await sql.raw(
      "CREATE INDEX IF NOT EXISTS idx_feedbacks_proposal_id ON feedbacks(proposal_id)"
    ).run()
    try await sql.raw(
      "CREATE INDEX IF NOT EXISTS idx_feedbacks_proposal_device ON feedbacks(proposal_id, device_id)"
    ).run()
  }

  func revert(on database: Database) async throws {
    guard let sql = database as? SQLDatabase else { return }
    try await sql.raw("DROP INDEX IF EXISTS idx_feedbacks_proposal_id").run()
    try await sql.raw("DROP INDEX IF EXISTS idx_feedbacks_proposal_device").run()
  }
}
