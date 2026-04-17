import Foundation
import JWT

/// JWT payload for verified Luma ticket holders (short-lived)
struct WorkshopVerifyPayload: JWTPayload, Sendable {
  var subject: SubjectClaim
  var name: String
  var expiration: ExpirationClaim

  init(email: String, name: String) {
    self.subject = SubjectClaim(value: email)
    self.name = name
    self.expiration = ExpirationClaim(value: Date().addingTimeInterval(1800))
  }

  func verify(using algorithm: some JWTAlgorithm) throws {
    try expiration.verifyNotExpired()
  }
}
