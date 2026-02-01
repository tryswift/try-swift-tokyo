import Foundation

/// Proposal review status for the CfP system
public enum ProposalStatus: String, Codable, Sendable, Equatable, CaseIterable {
  case submitted
  case accepted
  case rejected
  case withdrawn

  public var displayName: String {
    switch self {
    case .submitted:
      return "Submitted"
    case .accepted:
      return "Accepted"
    case .rejected:
      return "Rejected"
    case .withdrawn:
      return "Withdrawn"
    }
  }

  /// Bootstrap badge CSS class
  public var badgeClass: String {
    switch self {
    case .submitted:
      return "bg-secondary"
    case .accepted:
      return "bg-success"
    case .rejected:
      return "bg-danger"
    case .withdrawn:
      return "bg-warning text-dark"
    }
  }
}
