import Fluent

/// Migration to create the conferences table
struct CreateConference: AsyncMigration {
  func prepare(on database: Database) async throws {
    try await database.schema(Conference.schema)
      .id()
      .field("path", .string, .required)
      .field("display_name", .string, .required)
      .field("description_en", .string)
      .field("description_ja", .string)
      .field("year", .int, .required)
      .field("is_open", .bool, .required)
      .field("deadline", .datetime)
      .field("start_date", .datetime)
      .field("end_date", .datetime)
      .field("location", .string)
      .field("website_url", .string)
      .field("created_at", .datetime)
      .field("updated_at", .datetime)
      .unique(on: "path")
      .create()
  }
  
  func revert(on database: Database) async throws {
    try await database.schema(Conference.schema).delete()
  }
}
