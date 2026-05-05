import Foundation

public struct SponsorApplicationDTO: Codable, Sendable, Equatable, Identifiable {
  public let id: UUID
  public let organizationID: UUID
  public let planID: UUID
  public let conferenceID: UUID
  public let status: SponsorApplicationStatus
  public let payload: SponsorApplicationFormPayload
  public let submittedAt: Date?
  public let decidedAt: Date?
  public let decisionNote: String?

  public init(
    id: UUID, organizationID: UUID, planID: UUID, conferenceID: UUID,
    status: SponsorApplicationStatus, payload: SponsorApplicationFormPayload,
    submittedAt: Date?, decidedAt: Date?, decisionNote: String?
  ) {
    self.id = id
    self.organizationID = organizationID
    self.planID = planID
    self.conferenceID = conferenceID
    self.status = status
    self.payload = payload
    self.submittedAt = submittedAt
    self.decidedAt = decidedAt
    self.decisionNote = decisionNote
  }
}
