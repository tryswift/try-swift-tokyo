import Foundation
import JWT
import SharedModels

struct SponsorJWTPayload: JWTPayload, Sendable {
  var subject: SubjectClaim
  var orgID: UUID?
  var role: SponsorMemberRole?
  var locale: SponsorPortalLocale
  var expiration: ExpirationClaim
  var issuedAt: IssuedAtClaim

  init(
    userID: UUID,
    orgID: UUID?,
    role: SponsorMemberRole?,
    locale: SponsorPortalLocale
  ) {
    self.subject = SubjectClaim(value: userID.uuidString)
    self.orgID = orgID
    self.role = role
    self.locale = locale
    self.expiration = ExpirationClaim(value: Date().addingTimeInterval(86400 * 30))
    self.issuedAt = IssuedAtClaim(value: Date())
  }

  func verify(using algorithm: some JWTAlgorithm) throws {
    try expiration.verifyNotExpired()
  }

  var sponsorUserID: UUID? { UUID(uuidString: subject.value) }
}
