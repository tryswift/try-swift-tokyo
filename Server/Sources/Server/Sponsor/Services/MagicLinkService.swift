import Fluent
import Foundation
import Vapor

enum MagicLinkService {
  struct Issued: Sendable {
    let rawToken: String
    let tokenID: UUID
    let expiresAt: Date
  }

  static let defaultTTL: Duration = .seconds(30 * 60)

  static func issue(
    for user: SponsorUser,
    on db: Database,
    ttl: Duration = defaultTTL,
    now: @Sendable () -> Date = { Date() }
  ) async throws -> Issued {
    let raw = randomURLSafeToken(byteCount: 32)
    let hashed = hash(raw)
    let expires = now().addingTimeInterval(TimeInterval(ttl.components.seconds))
    let token = MagicLinkToken(
      userID: try user.requireID(), tokenHash: hashed, expiresAt: expires)
    try await token.save(on: db)
    return Issued(rawToken: raw, tokenID: try token.requireID(), expiresAt: expires)
  }

  static func verify(
    rawToken: String,
    on db: Database,
    now: @Sendable () -> Date = { Date() }
  ) async throws -> SponsorUser? {
    let hashed = hash(rawToken)
    let nowDate = now()
    return try await db.transaction { transaction in
      guard
        let token = try await MagicLinkToken.query(on: transaction)
          .filter(\.$tokenHash == hashed)
          .with(\.$user)
          .first()
      else { return nil }
      if token.usedAt != nil { return nil }
      if token.expiresAt <= nowDate { return nil }

      token.usedAt = nowDate
      try await token.save(on: transaction)
      return token.user
    }
  }

  static func hash(_ raw: String) -> String {
    SecureToken.sha256Hex(raw)
  }

  private static func randomURLSafeToken(byteCount: Int) -> String {
    SecureToken.urlSafe(byteCount: byteCount)
  }
}
