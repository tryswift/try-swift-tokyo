import Fluent

/// Migration to create schedule_slots table for timetable management
struct CreateScheduleSlot: AsyncMigration {
  func prepare(on database: Database) async throws {
    try await database.schema(ScheduleSlot.schema)
      .id()
      .field(
        "conference_id", .uuid, .required, .references(Conference.schema, "id", onDelete: .cascade)
      )
      .field("proposal_id", .uuid, .references(Proposal.schema, "id", onDelete: .setNull))
      .field("day", .int, .required)
      .field("start_time", .datetime, .required)
      .field("end_time", .datetime)
      .field("slot_type", .string, .required)
      .field("custom_title", .string)
      .field("custom_title_ja", .string)
      .field("description_text", .string)
      .field("description_text_ja", .string)
      .field("place", .string)
      .field("place_ja", .string)
      .field("sort_order", .int, .required)
      .field("created_at", .datetime)
      .field("updated_at", .datetime)
      .create()
  }

  func revert(on database: Database) async throws {
    try await database.schema(ScheduleSlot.schema).delete()
  }
}
