import Foundation

/// Snapshot of the application form values at submission time.
/// Stored as JSONB in `sponsor_applications.payload`.
public struct SponsorApplicationFormPayload: Codable, Sendable, Equatable {
  public let billingContactName: String
  public let billingEmail: String
  public let invoicingNotes: String?
  public let logoNote: String?
  public let acceptedTerms: Bool
  public let locale: SponsorPortalLocale

  public init(
    billingContactName: String, billingEmail: String, invoicingNotes: String?,
    logoNote: String?, acceptedTerms: Bool, locale: SponsorPortalLocale
  ) {
    self.billingContactName = billingContactName
    self.billingEmail = billingEmail
    self.invoicingNotes = invoicingNotes
    self.logoNote = logoNote
    self.acceptedTerms = acceptedTerms
    self.locale = locale
  }
}
