import Fluent
import SharedModels
import Vapor

final class SponsorApplication: Model, Content, @unchecked Sendable {
  static let schema = "sponsor_applications"

  @ID(key: .id) var id: UUID?
  @Parent(key: "organization_id") var organization: SponsorOrganization
  @Parent(key: "plan_id") var plan: SponsorPlan
  @Parent(key: "conference_id") var conference: Conference
  @Field(key: "status") var status: SponsorApplicationStatus
  @Field(key: "payload") var payload: SponsorApplicationFormPayload
  @OptionalField(key: "submitted_at") var submittedAt: Date?
  @OptionalField(key: "decided_at") var decidedAt: Date?
  @OptionalField(key: "decided_by_user_id") var decidedByUserID: UUID?
  @OptionalField(key: "decision_note") var decisionNote: String?
  @Timestamp(key: "created_at", on: .create) var createdAt: Date?
  @Timestamp(key: "updated_at", on: .update) var updatedAt: Date?

  init() {}

  init(
    id: UUID? = nil, organizationID: UUID, planID: UUID, conferenceID: UUID,
    status: SponsorApplicationStatus = .submitted,
    payload: SponsorApplicationFormPayload,
    submittedAt: Date? = nil
  ) {
    self.id = id
    self.$organization.id = organizationID
    self.$plan.id = planID
    self.$conference.id = conferenceID
    self.status = status
    self.payload = payload
    self.submittedAt = submittedAt
  }

  func toDTO() throws -> SponsorApplicationDTO {
    guard let id else { throw Abort(.internalServerError, reason: "SponsorApplication missing id") }
    return SponsorApplicationDTO(
      id: id, organizationID: $organization.id, planID: $plan.id,
      conferenceID: $conference.id, status: status, payload: payload,
      submittedAt: submittedAt, decidedAt: decidedAt, decisionNote: decisionNote
    )
  }
}
