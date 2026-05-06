import Fluent
import SharedModels
import Vapor

/// Authenticated applicant for the student.tryswift.jp portal.
///
/// Stored separately from `User` (GitHub-OAuth backed) and `SponsorUser`
/// because students sign in with email + magic link only and the records
/// have a different lifecycle and column set.
final class StudentUser: Model, Content, @unchecked Sendable {
  static let schema = "student_users"

  @ID(key: .id) var id: UUID?
  @Field(key: "email") var email: String
  @OptionalField(key: "display_name") var displayName: String?
  @Field(key: "locale") var locale: ScholarshipPortalLocale
  @Timestamp(key: "created_at", on: .create) var createdAt: Date?
  @Timestamp(key: "updated_at", on: .update) var updatedAt: Date?

  init() {}

  init(
    id: UUID? = nil,
    email: String,
    displayName: String? = nil,
    locale: ScholarshipPortalLocale = .default
  ) {
    self.id = id
    self.email = email.lowercased()
    self.displayName = displayName
    self.locale = locale
  }
}
