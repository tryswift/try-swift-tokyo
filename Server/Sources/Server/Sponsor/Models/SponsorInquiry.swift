import Fluent
import SharedModels
import Vapor

final class SponsorInquiry: Model, Content, @unchecked Sendable {
  static let schema = "sponsor_inquiries"

  enum Status: String, Codable, Sendable { case open, contacted, converted, archived }

  @ID(key: .id) var id: UUID?
  @Parent(key: "conference_id") var conference: Conference
  @Field(key: "company_name") var companyName: String
  @Field(key: "contact_name") var contactName: String
  @Field(key: "email") var email: String
  @OptionalField(key: "desired_plan_slug") var desiredPlanSlug: String?
  @Field(key: "message") var message: String
  @Field(key: "locale") var locale: SponsorPortalLocale
  @Field(key: "status") var status: Status
  @Timestamp(key: "created_at", on: .create) var createdAt: Date?

  init() {}

  init(
    id: UUID? = nil, conferenceID: UUID, companyName: String, contactName: String,
    email: String, desiredPlanSlug: String? = nil, message: String,
    locale: SponsorPortalLocale, status: Status = .open
  ) {
    self.id = id
    self.$conference.id = conferenceID
    self.companyName = companyName
    self.contactName = contactName
    self.email = email.lowercased()
    self.desiredPlanSlug = desiredPlanSlug
    self.message = message
    self.locale = locale
    self.status = status
  }

  func toDTO() throws -> SponsorInquiryDTO {
    guard let id else { throw Abort(.internalServerError, reason: "SponsorInquiry missing id") }
    return SponsorInquiryDTO(
      id: id, conferenceID: $conference.id, companyName: companyName,
      contactName: contactName, email: email, desiredPlanSlug: desiredPlanSlug,
      message: message, locale: locale, createdAt: createdAt
    )
  }
}
