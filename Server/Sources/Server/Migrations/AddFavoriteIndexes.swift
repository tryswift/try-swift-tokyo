import Fluent
import SQLKit

/// Migration to add indexes to favorites table
struct AddFavoriteIndexes: AsyncMigration {
  func prepare(on database: Database) async throws {
    guard let sql = database as? SQLDatabase else { return }
    try await sql.raw("CREATE INDEX IF NOT EXISTS idx_favorites_device_id ON favorites(device_id)")
      .run()
  }

  func revert(on database: Database) async throws {
    guard let sql = database as? SQLDatabase else { return }
    try await sql.raw("DROP INDEX IF EXISTS idx_favorites_device_id").run()
  }
}
