import Fluent
import SharedModels
import Vapor

/// Per-conference scholarship budget set by organizers.
final class ScholarshipBudget: Model, Content, @unchecked Sendable {
  static let schema = "scholarship_budgets"

  @ID(key: .id) var id: UUID?

  @Parent(key: "conference_id") var conference: Conference

  /// Total available budget in JPY.
  @Field(key: "total_budget") var totalBudget: Int

  @OptionalField(key: "notes") var notes: String?

  @Timestamp(key: "created_at", on: .create) var createdAt: Date?
  @Timestamp(key: "updated_at", on: .update) var updatedAt: Date?

  init() {}

  init(
    id: UUID? = nil,
    conferenceID: UUID,
    totalBudget: Int,
    notes: String? = nil
  ) {
    self.id = id
    self.$conference.id = conferenceID
    self.totalBudget = totalBudget
    self.notes = notes
  }

  func toDTO() throws -> ScholarshipBudgetDTO {
    guard let id else {
      throw Abort(.internalServerError, reason: "ScholarshipBudget missing id")
    }
    return ScholarshipBudgetDTO(
      id: id,
      conferenceID: $conference.id,
      totalBudget: totalBudget,
      notes: notes,
      createdAt: createdAt,
      updatedAt: updatedAt
    )
  }
}
