import Fluent

/// Migration to add the JSONB `accepted_formats` column to conferences.
///
/// Nullable with no default: existing rows decode as `nil`, surfaced as an empty
/// array by `Conference.toDTO()`.
struct AddConferenceAcceptedFormats: AsyncMigration {
  func prepare(on database: Database) async throws {
    try await database.schema(Conference.schema)
      .field("accepted_formats", .json)
      .update()
  }

  func revert(on database: Database) async throws {
    try await database.schema(Conference.schema)
      .deleteField("accepted_formats")
      .update()
  }
}
