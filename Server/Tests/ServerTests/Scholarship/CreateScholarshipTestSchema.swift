import Fluent

@testable import Server

/// In-memory SQLite schema for scholarship-portal integration tests.
/// Mirrors the production migrations but lives in a single file so tests can
/// stand up an isolated app per test case.
struct CreateScholarshipTestSchema: AsyncMigration {
  var name: String { "CreateScholarshipTestSchema" }

  func prepare(on database: Database) async throws {
    try await database.schema(User.schema)
      .id()
      .field("github_id", .int, .required)
      .field("username", .string, .required)
      .field("role", .string, .required)
      .field("display_name", .string).field("email", .string).field("bio", .string)
      .field("url", .string).field("organization", .string).field("avatar_url", .string)
      .field("created_at", .datetime).field("updated_at", .datetime)
      .create()

    try await database.schema(Conference.schema)
      .id().field("path", .string, .required).field("display_name", .string, .required)
      .field("description_en", .string).field("description_ja", .string)
      .field("year", .int, .required).field("is_open", .bool, .required)
      .field("is_accepting_sponsors", .bool, .required, .sql(.default(false)))
      .field("is_published", .bool, .required, .sql(.default(true)))
      .field("deadline", .datetime).field("start_date", .datetime).field("end_date", .datetime)
      .field("location", .string).field("website_url", .string)
      .field("created_at", .datetime).field("updated_at", .datetime)
      .create()

    try await database.schema(StudentUser.schema)
      .id().field("email", .string, .required).field("display_name", .string)
      .field("locale", .string, .required)
      .field("created_at", .datetime).field("updated_at", .datetime)
      .unique(on: "email").create()

    try await database.schema(StudentMagicLinkToken.schema)
      .id()
      .field(
        "student_user_id", .uuid, .required, .references(StudentUser.schema, "id")
      )
      .field("token_hash", .string, .required)
      .field("purpose", .string, .required)
      .field("expires_at", .datetime, .required)
      .field("used_at", .datetime).field("created_at", .datetime)
      .unique(on: "token_hash").create()

    try await database.schema(ScholarshipApplication.schema)
      .id()
      .field("conference_id", .uuid, .required, .references(Conference.schema, "id"))
      .field("applicant_id", .uuid, .required, .references(StudentUser.schema, "id"))
      .field("email", .string, .required).field("name", .string, .required)
      .field("school_and_faculty", .string, .required).field("current_year", .string, .required)
      .field("portfolio", .string).field("github_account", .string)
      .field("purposes", .json, .required).field("language_preference", .string, .required)
      .field("existing_ticket_info", .string).field("support_type", .string, .required)
      .field("travel_details", .json).field("accommodation_details", .json)
      .field("total_estimated_cost", .int).field("desired_support_amount", .int)
      .field("self_payment_info", .string)
      .field("agreed_travel_regulations", .bool, .required)
      .field("agreed_application_confirmation", .bool, .required)
      .field("agreed_privacy", .bool, .required)
      .field("agreed_code_of_conduct", .bool, .required)
      .field("additional_comments", .string).field("status", .string, .required)
      .field("approved_amount", .int).field("organizer_notes", .string)
      .field("created_at", .datetime).field("updated_at", .datetime)
      .unique(on: "conference_id", "applicant_id")
      .create()

    try await database.schema(ScholarshipBudget.schema)
      .id()
      .field("conference_id", .uuid, .required, .references(Conference.schema, "id"))
      .field("total_budget", .int, .required).field("notes", .string)
      .field("created_at", .datetime).field("updated_at", .datetime)
      .unique(on: "conference_id").create()
  }

  func revert(on database: Database) async throws {
    for s in [
      ScholarshipBudget.schema, ScholarshipApplication.schema,
      StudentMagicLinkToken.schema, StudentUser.schema,
      Conference.schema, User.schema,
    ] {
      try await database.schema(s).delete()
    }
  }
}
