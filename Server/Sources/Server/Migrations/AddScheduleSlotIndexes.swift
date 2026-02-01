import Fluent

/// Migration to add indexes and constraints to schedule_slots table
struct AddScheduleSlotIndexes: AsyncMigration {
  func prepare(on database: Database) async throws {
    try await database.schema(ScheduleSlot.schema)
      .unique(on: "conference_id", "proposal_id")
      .update()
  }

  func revert(on database: Database) async throws {
    try await database.schema(ScheduleSlot.schema)
      .deleteUnique(on: "conference_id", "proposal_id")
      .update()
  }
}
