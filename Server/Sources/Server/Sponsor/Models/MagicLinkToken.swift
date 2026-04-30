import Fluent
import Vapor

final class MagicLinkToken: Model, Content, @unchecked Sendable {
  static let schema = "sponsor_magic_link_tokens"

  enum Purpose: String, Codable, Sendable { case login }

  @ID(key: .id) var id: UUID?
  @Parent(key: "sponsor_user_id") var user: SponsorUser
  @Field(key: "token_hash") var tokenHash: String
  @Field(key: "purpose") var purpose: Purpose
  @Field(key: "expires_at") var expiresAt: Date
  @OptionalField(key: "used_at") var usedAt: Date?
  @Timestamp(key: "created_at", on: .create) var createdAt: Date?

  init() {}

  init(
    id: UUID? = nil, userID: UUID, tokenHash: String,
    purpose: Purpose = .login, expiresAt: Date
  ) {
    self.id = id
    self.$user.id = userID
    self.tokenHash = tokenHash
    self.purpose = purpose
    self.expiresAt = expiresAt
  }
}
