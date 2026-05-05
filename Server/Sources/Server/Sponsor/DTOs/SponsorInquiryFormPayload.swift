import SharedModels
import Vapor

struct SponsorInquiryFormPayload: Content {
  let companyName: String
  let contactName: String
  let email: String
  let message: String?
}
