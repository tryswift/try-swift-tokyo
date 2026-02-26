import Fluent
import Vapor

/// Scholarship budget model for tracking available funds per conference
final class ScholarshipBudget: Model, Content, @unchecked Sendable {
  static let schema = "scholarship_budgets"

  @ID(key: .id)
  var id: UUID?

  /// Reference to the conference
  @Parent(key: "conference_id")
  var conference: Conference

  /// Total budget in yen
  @Field(key: "total_budget")
  var totalBudget: Int

  /// Admin notes
  @OptionalField(key: "notes")
  var notes: String?

  @Timestamp(key: "created_at", on: .create)
  var createdAt: Date?

  @Timestamp(key: "updated_at", on: .update)
  var updatedAt: Date?

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
}
