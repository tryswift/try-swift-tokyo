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
      // Read the token row with its associated user.
      guard
        let token = try await MagicLinkToken.query(on: transaction)
          .filter(\.$tokenHash == hashed)
          .with(\.$user)
          .first()
      else { return nil }
      if token.usedAt != nil { return nil }
      if token.expiresAt <= nowDate { return nil }

      // Atomically claim the token using a conditional UPDATE that targets only
      // rows where used_at IS NULL. If a concurrent transaction claimed it first,
      // this UPDATE affects 0 rows and the subsequent re-read will show a non-nil
      // usedAt, causing us to return nil (lost the race).
      let tokenID = try token.requireID()
      try await MagicLinkToken.query(on: transaction)
        .filter(\.$id == tokenID)
        .filter(\.$usedAt == .none)
        .set(\.$usedAt, to: nowDate)
        .update()

      // Re-read inside the same transaction to confirm we own the claim.
      guard
        let after = try await MagicLinkToken.find(tokenID, on: transaction),
        after.usedAt == nowDate
      else {
        return nil  // Lost the race — another transaction claimed first.
      }
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
