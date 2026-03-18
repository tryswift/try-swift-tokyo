import Fluent
import Vapor

/// Application status for workshop lottery
enum WorkshopApplicationStatus: String, Codable, Sendable {
  case pending
  case won
  case lost
}

/// Workshop application model for attendee lottery entries
final class WorkshopApplication: Model, Content, @unchecked Sendable {
  static let schema = "workshop_applications"

  @ID(key: .id)
  var id: UUID?

  /// Applicant email (verified via Luma ticket)
  @Field(key: "email")
  var email: String

  /// Applicant display name
  @Field(key: "applicant_name")
  var applicantName: String

  /// First choice workshop
  @Parent(key: "first_choice_id")
  var firstChoice: WorkshopRegistration

  /// Second choice workshop (optional)
  @OptionalParent(key: "second_choice_id")
  var secondChoice: WorkshopRegistration?

  /// Third choice workshop (optional)
  @OptionalParent(key: "third_choice_id")
  var thirdChoice: WorkshopRegistration?

  /// Assigned workshop after lottery (nil until lottery runs)
  @OptionalParent(key: "assigned_workshop_id")
  var assignedWorkshop: WorkshopRegistration?

  /// Application status
  @Field(key: "status")
  var status: WorkshopApplicationStatus

  /// Luma guest ID after ticket is sent
  @OptionalField(key: "luma_guest_id")
  var lumaGuestID: String?

  @Timestamp(key: "created_at", on: .create)
  var createdAt: Date?

  @Timestamp(key: "updated_at", on: .update)
  var updatedAt: Date?

  init() {}

  init(
    id: UUID? = nil,
    email: String,
    applicantName: String,
    firstChoiceID: UUID,
    secondChoiceID: UUID? = nil,
    thirdChoiceID: UUID? = nil,
    status: WorkshopApplicationStatus = .pending
  ) {
    self.id = id
    self.email = email
    self.applicantName = applicantName
    self.$firstChoice.id = firstChoiceID
    self.$secondChoice.id = secondChoiceID
    self.$thirdChoice.id = thirdChoiceID
    self.status = status
  }
}
