import Foundation

public enum SponsorApplicationStatus: String, Codable, Sendable, Equatable, CaseIterable {
  case draft
  case submitted
  case underReview = "under_review"
  case approved
  case rejected
  case withdrawn
}
