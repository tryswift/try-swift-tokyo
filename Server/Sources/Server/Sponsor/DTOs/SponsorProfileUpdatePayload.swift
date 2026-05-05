import Vapor

struct SponsorProfileUpdatePayload: Content {
  let legalName: String
  let displayName: String
  let country: String?
  let billingAddress: String?
  let websiteURL: String?
}
