import Foundation

/// Scholarship application review status
public enum ScholarshipApplicationStatus: String, Codable, Sendable, Equatable, CaseIterable {
  case submitted
  case approved
  case rejected
  case withdrawn

  public var displayName: String {
    switch self {
    case .submitted:
      return "Submitted"
    case .approved:
      return "Approved"
    case .rejected:
      return "Rejected"
    case .withdrawn:
      return "Withdrawn"
    }
  }

  public var displayNameJa: String {
    switch self {
    case .submitted:
      return "申請中"
    case .approved:
      return "承認済み"
    case .rejected:
      return "不採択"
    case .withdrawn:
      return "取り下げ"
    }
  }

  /// Bootstrap badge CSS class
  public var badgeClass: String {
    switch self {
    case .submitted:
      return "bg-secondary"
    case .approved:
      return "bg-success"
    case .rejected:
      return "bg-danger"
    case .withdrawn:
      return "bg-warning text-dark"
    }
  }
}
