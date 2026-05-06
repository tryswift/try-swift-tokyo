import Foundation

/// Per-conference scholarship budget set by organizers.
public struct ScholarshipBudgetDTO: Codable, Sendable, Equatable, Identifiable {
  public let id: UUID
  public let conferenceID: UUID
  public let totalBudget: Int
  public let notes: String?
  public let createdAt: Date?
  public let updatedAt: Date?

  public init(
    id: UUID,
    conferenceID: UUID,
    totalBudget: Int,
    notes: String? = nil,
    createdAt: Date? = nil,
    updatedAt: Date? = nil
  ) {
    self.id = id
    self.conferenceID = conferenceID
    self.totalBudget = totalBudget
    self.notes = notes
    self.createdAt = createdAt
    self.updatedAt = updatedAt
  }
}

/// Aggregate budget view rendered on organizer pages.
public struct ScholarshipBudgetSummaryDTO: Codable, Sendable, Equatable {
  public let totalBudget: Int?
  public let approvedTotal: Int
  public let remaining: Int?

  public init(totalBudget: Int?, approvedTotal: Int) {
    self.totalBudget = totalBudget
    self.approvedTotal = approvedTotal
    self.remaining = totalBudget.map { $0 - approvedTotal }
  }
}
