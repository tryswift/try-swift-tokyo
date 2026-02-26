import Fluent

struct CreateScholarshipApplication: AsyncMigration {
  func prepare(on database: Database) async throws {
    try await database.schema(ScholarshipApplication.schema)
      .id()
      .field("conference_id", .uuid, .required, .references(Conference.schema, "id", onDelete: .cascade))
      .field("applicant_id", .uuid, .required, .references(User.schema, "id", onDelete: .cascade))
      .field("email", .string, .required)
      .field("name", .string, .required)
      .field("school_and_faculty", .string, .required)
      .field("current_year", .string, .required)
      .field("portfolio", .string)
      .field("github_account", .string)
      .field("purposes", .json, .required)
      .field("language_preference", .string, .required)
      .field("existing_ticket_info", .string)
      .field("support_type", .string, .required)
      .field("travel_details", .json)
      .field("accommodation_details", .json)
      .field("total_estimated_cost", .int)
      .field("desired_support_amount", .int)
      .field("self_payment_info", .string)
      .field("agreed_travel_regulations", .bool, .required)
      .field("agreed_application_confirmation", .bool, .required)
      .field("agreed_privacy", .bool, .required)
      .field("agreed_code_of_conduct", .bool, .required)
      .field("additional_comments", .string)
      .field("status", .string, .required)
      .field("approved_amount", .int)
      .field("organizer_notes", .string)
      .field("created_at", .datetime)
      .field("updated_at", .datetime)
      .unique(on: "conference_id", "applicant_id")
      .create()
  }

  func revert(on database: Database) async throws {
    try await database.schema(ScholarshipApplication.schema).delete()
  }
}
