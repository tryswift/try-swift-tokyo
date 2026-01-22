import Foundation

/// User role for the CfP system
/// - admin: Organizer with full access (members of try-swift GitHub org)
/// - speaker: Regular user who can submit proposals
public enum UserRole: String, Codable, Sendable, Equatable, CaseIterable {
  case admin
  case speaker

  public var isAdmin: Bool {
    self == .admin
  }

  public var displayName: String {
    switch self {
    case .admin:
      return "Organizer"
    case .speaker:
      return "Speaker"
    }
  }
}
