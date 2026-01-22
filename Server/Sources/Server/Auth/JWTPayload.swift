import JWT
import Foundation
import SharedModels

/// JWT Payload for authenticated users
struct UserJWTPayload: JWTPayload, Sendable {
  /// Subject (user ID)
  var subject: SubjectClaim

  /// User's role
  var role: UserRole

  /// GitHub username
  var username: String

  /// Expiration time
  var expiration: ExpirationClaim

  /// Issued at time
  var issuedAt: IssuedAtClaim

  init(userID: UUID, role: UserRole, username: String) {
    self.subject = SubjectClaim(value: userID.uuidString)
    self.role = role
    self.username = username
    self.expiration = ExpirationClaim(value: Date().addingTimeInterval(86400 * 7)) // 7 days
    self.issuedAt = IssuedAtClaim(value: Date())
  }

  func verify(using algorithm: some JWTAlgorithm) throws {
    try expiration.verifyNotExpired()
  }

  var userID: UUID? {
    UUID(uuidString: subject.value)
  }
}
