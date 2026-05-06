import Fluent
import Foundation
import Vapor

/// Issues and verifies single-use, time-bounded magic-link tokens for
/// student.tryswift.jp logins. Mirrors `MagicLinkService` but operates on
/// `StudentUser` / `StudentMagicLinkToken` so the two portals can keep their
/// authentication tables independent.
enum ScholarshipMagicLinkService {
  struct Issued: Sendable {
    let rawToken: String
    let tokenID: UUID
    let expiresAt: Date
  }

  static let defaultTTL: Duration = .seconds(30 * 60)

  static func issue(
    for user: StudentUser,
    on db: Database,
    ttl: Duration = defaultTTL,
    now: @Sendable () -> Date = { Date() }
  ) async throws -> Issued {
    let raw = SecureToken.urlSafe(byteCount: 32)
    let hashed = SecureToken.sha256Hex(raw)
    let expires = now().addingTimeInterval(TimeInterval(ttl.components.seconds))
    let token = StudentMagicLinkToken(
      userID: try user.requireID(),
      tokenHash: hashed,
      expiresAt: expires
    )
    try await token.save(on: db)
    return Issued(rawToken: raw, tokenID: try token.requireID(), expiresAt: expires)
  }

  static func verify(
    rawToken: String,
    on db: Database,
    now: @Sendable () -> Date = { Date() }
  ) async throws -> StudentUser? {
    let hashed = SecureToken.sha256Hex(rawToken)
    // See MagicLinkService for the rationale behind microsecond alignment:
    // SQLite's Date round-trip rounds to microseconds, so the post-UPDATE
    // re-read fails byte equality on Linux without this alignment.
    let nowDate = microsecondAligned(now())
    return try await db.transaction { transaction in
      guard
        let token = try await StudentMagicLinkToken.query(on: transaction)
          .filter(\.$tokenHash == hashed)
          .with(\.$user)
          .first()
      else { return nil }
      if token.usedAt != nil { return nil }
      if token.expiresAt <= nowDate { return nil }

      let tokenID = try token.requireID()
      try await StudentMagicLinkToken.query(on: transaction)
        .filter(\.$id == tokenID)
        .filter(\.$usedAt == .none)
        .set(\.$usedAt, to: nowDate)
        .update()

      guard
        let after = try await StudentMagicLinkToken.find(tokenID, on: transaction),
        after.usedAt == nowDate
      else {
        return nil  // Lost the race — another transaction claimed the token first.
      }
      return token.user
    }
  }

  private static func microsecondAligned(_ date: Date) -> Date {
    let micros = (date.timeIntervalSinceReferenceDate * 1_000_000).rounded()
    return Date(timeIntervalSinceReferenceDate: micros / 1_000_000)
  }
}
