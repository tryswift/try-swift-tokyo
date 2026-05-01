import Crypto
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
    let digest = SHA256.hash(data: Data(raw.utf8))
    return digest.map { String(format: "%02x", $0) }.joined()
  }

  private static func randomURLSafeToken(byteCount: Int) -> String {
    var bytes = [UInt8](repeating: 0, count: byteCount)
    for i in 0..<byteCount { bytes[i] = UInt8.random(in: .min ... .max) }
    return Data(bytes).base64URLEncodedString()
  }
}

extension Data {
  fileprivate func base64URLEncodedString() -> String {
    base64EncodedString()
      .replacingOccurrences(of: "+", with: "-")
      .replacingOccurrences(of: "/", with: "_")
      .replacingOccurrences(of: "=", with: "")
  }
}
