import Fluent

/// Migration to create workshop_applications table
struct CreateWorkshopApplication: AsyncMigration {
  func prepare(on database: Database) async throws {
    try await database.schema(WorkshopApplication.schema)
      .id()
      .field("email", .string, .required)
      .field("applicant_name", .string, .required)
      .field(
        "first_choice_id", .uuid, .required,
        .references(WorkshopRegistration.schema, "id", onDelete: .cascade)
      )
      .field(
        "second_choice_id", .uuid,
        .references(WorkshopRegistration.schema, "id", onDelete: .cascade)
      )
      .field(
        "third_choice_id", .uuid,
        .references(WorkshopRegistration.schema, "id", onDelete: .cascade)
      )
      .field(
        "assigned_workshop_id", .uuid,
        .references(WorkshopRegistration.schema, "id", onDelete: .setNull)
      )
      .field("status", .string, .required)
      .field("luma_guest_id", .string)
      .field("created_at", .datetime)
      .field("updated_at", .datetime)
      .unique(on: "email")
      .create()
  }

  func revert(on database: Database) async throws {
    try await database.schema(WorkshopApplication.schema).delete()
  }
}
