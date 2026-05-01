import Fluent

@testable import Server

struct CreateSponsorTestSchema: AsyncMigration {
  var name: String { "CreateSponsorTestSchema" }

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
      .field("deadline", .datetime).field("start_date", .datetime).field("end_date", .datetime)
      .field("location", .string).field("website_url", .string)
      .field("created_at", .datetime).field("updated_at", .datetime)
      .create()

    try await database.schema(SponsorOrganization.schema)
      .id().field("legal_name", .string, .required).field("display_name", .string, .required)
      .field("country", .string).field("billing_address", .string).field("website_url", .string)
      .field("status", .string, .required)
      .field("created_at", .datetime).field("updated_at", .datetime).create()

    try await database.schema(SponsorUser.schema)
      .id().field("email", .string, .required).field("display_name", .string)
      .field("locale", .string, .required)
      .field("created_at", .datetime).field("updated_at", .datetime)
      .unique(on: "email").create()

    try await database.schema(SponsorMembership.schema)
      .id()
      .field("organization_id", .uuid, .required, .references(SponsorOrganization.schema, "id"))
      .field("sponsor_user_id", .uuid, .required, .references(SponsorUser.schema, "id"))
      .field("role", .string, .required)
      .field("invited_by_sponsor_user_id", .uuid)
      .field("created_at", .datetime)
      .unique(on: "organization_id", "sponsor_user_id")
      .create()

    try await database.schema(SponsorPlan.schema)
      .id().field("conference_id", .uuid, .required, .references(Conference.schema, "id"))
      .field("slug", .string, .required).field("sort_order", .int, .required)
      .field("price_jpy", .int, .required).field("capacity", .int)
      .field("deadline_at", .datetime).field("is_active", .bool, .required, .sql(.default(true)))
      .field("created_at", .datetime).field("updated_at", .datetime)
      .unique(on: "conference_id", "slug").create()

    try await database.schema(SponsorPlanLocalization.schema)
      .id().field("plan_id", .uuid, .required, .references(SponsorPlan.schema, "id"))
      .field("locale", .string, .required).field("name", .string, .required)
      .field("summary", .string, .required).field("benefits", .json, .required)
      .unique(on: "plan_id", "locale").create()

    try await database.schema(SponsorInquiry.schema)
      .id().field("conference_id", .uuid, .required, .references(Conference.schema, "id"))
      .field("company_name", .string, .required).field("contact_name", .string, .required)
      .field("email", .string, .required).field("desired_plan_slug", .string)
      .field("message", .string, .required).field("locale", .string, .required)
      .field("status", .string, .required).field("created_at", .datetime).create()

    try await database.schema(SponsorApplication.schema)
      .id()
      .field("organization_id", .uuid, .required, .references(SponsorOrganization.schema, "id"))
      .field("plan_id", .uuid, .required, .references(SponsorPlan.schema, "id"))
      .field("conference_id", .uuid, .required, .references(Conference.schema, "id"))
      .field("status", .string, .required).field("payload", .json, .required)
      .field("submitted_at", .datetime).field("decided_at", .datetime)
      .field("decided_by_user_id", .uuid).field("decision_note", .string)
      .field("created_at", .datetime).field("updated_at", .datetime).create()

    try await database.schema(MagicLinkToken.schema)
      .id().field("sponsor_user_id", .uuid, .required, .references(SponsorUser.schema, "id"))
      .field("token_hash", .string, .required).field("purpose", .string, .required)
      .field("expires_at", .datetime, .required).field("used_at", .datetime)
      .field("created_at", .datetime)
      .unique(on: "token_hash").create()

    try await database.schema(SponsorInvitation.schema)
      .id()
      .field("organization_id", .uuid, .required, .references(SponsorOrganization.schema, "id"))
      .field("email", .string, .required).field("role", .string, .required)
      .field("token_hash", .string, .required).field("expires_at", .datetime, .required)
      .field("accepted_at", .datetime).field("invited_by_sponsor_user_id", .uuid, .required)
      .field("created_at", .datetime).unique(on: "token_hash").create()
  }

  func revert(on database: Database) async throws {
    for s in [
      SponsorInvitation.schema, MagicLinkToken.schema,
      SponsorApplication.schema, SponsorInquiry.schema,
      SponsorPlanLocalization.schema, SponsorPlan.schema,
      SponsorMembership.schema, SponsorUser.schema,
      SponsorOrganization.schema, Conference.schema, User.schema,
    ] {
      try await database.schema(s).delete()
    }
  }
}
