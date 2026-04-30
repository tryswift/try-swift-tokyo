import Fluent
import SharedModels
import Vapor

final class SponsorUser: Model, Content, @unchecked Sendable {
  static let schema = "sponsor_users"

  @ID(key: .id) var id: UUID?
  @Field(key: "email") var email: String
  @OptionalField(key: "display_name") var displayName: String?
  @Field(key: "locale") var locale: SponsorPortalLocale
  @Timestamp(key: "created_at", on: .create) var createdAt: Date?
  @Timestamp(key: "updated_at", on: .update) var updatedAt: Date?

  init() {}

  init(
    id: UUID? = nil, email: String, displayName: String? = nil,
    locale: SponsorPortalLocale = .default
  ) {
    self.id = id
    self.email = email.lowercased()
    self.displayName = displayName
    self.locale = locale
  }

  func toDTO() throws -> SponsorUserDTO {
    guard let id else { throw Abort(.internalServerError, reason: "SponsorUser missing id") }
    return SponsorUserDTO(
      id: id, email: email, displayName: displayName,
      locale: locale, createdAt: createdAt)
  }
}
