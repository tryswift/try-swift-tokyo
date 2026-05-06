import Foundation
import JWT
import SharedModels

/// Session JWT issued for student.tryswift.jp after a successful magic-link
/// verification.
struct StudentJWTPayload: JWTPayload, Sendable {
  var subject: SubjectClaim
  var locale: ScholarshipPortalLocale
  var expiration: ExpirationClaim
  var issuedAt: IssuedAtClaim

  init(userID: UUID, locale: ScholarshipPortalLocale) {
    self.subject = SubjectClaim(value: userID.uuidString)
    self.locale = locale
    self.expiration = ExpirationClaim(value: Date().addingTimeInterval(86400 * 30))
    self.issuedAt = IssuedAtClaim(value: Date())
  }

  func verify(using algorithm: some JWTAlgorithm) throws {
    try expiration.verifyNotExpired()
  }

  var studentUserID: UUID? { UUID(uuidString: subject.value) }
}
