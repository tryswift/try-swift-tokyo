import Vapor

// Browsers do not send unchecked checkboxes at all, so acceptedTerms must be optional.
struct SponsorApplicationFormPostPayload: Content {
  let planSlug: String
  let billingContactName: String
  let billingEmail: String
  let invoicingNotes: String?
  let logoNote: String?
  let acceptedTerms: String?
}
