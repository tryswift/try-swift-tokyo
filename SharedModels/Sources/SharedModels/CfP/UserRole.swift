import Foundation

// CfP types are iOS-only (not used in Android app)
#if !SKIP

  /// User role for the CfP system
  /// - admin: Organizer with full access (members of try-swift GitHub org)
  /// - invitedSpeaker: Invited speaker who can submit invited talks
  /// - speaker: Regular user who can submit proposals
  public enum UserRole: String, Codable, Sendable, Equatable, CaseIterable {
    case admin
    case invitedSpeaker
    case speaker

    public var isAdmin: Bool {
      self == .admin
    }

    public var isInvitedSpeaker: Bool {
      self == .invitedSpeaker
    }

    public var displayName: String {
      switch self {
      case .admin:
        return "Organizer"
      case .invitedSpeaker:
        return "Invited Speaker"
      case .speaker:
        return "Speaker"
      }
    }
  }

#endif
