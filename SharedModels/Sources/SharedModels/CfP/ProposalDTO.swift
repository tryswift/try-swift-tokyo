import Foundation

/// Talk duration options
public enum TalkDuration: String, Codable, Sendable, Equatable, CaseIterable {
  case regular = "20min"
  case lightning = "LT"
  case invited = "invited"

  public var displayName: String {
    switch self {
    case .regular:
      return "20 minutes"
    case .lightning:
      return "Lightning Talk (5 min)"
    case .invited:
      return "Invited Talk (20 min)"
    }
  }

  /// Whether this duration is only available for invited speakers
  public var isInvitedOnly: Bool {
    self == .invited
  }
}

/// Data Transfer Object for CfP (Call for Proposals)
/// Shared between Server and iOS Client
public struct ProposalDTO: Codable, Sendable, Equatable, Identifiable {
  public let id: UUID
  /// Conference ID (hash/UUID)
  public let conferenceId: UUID
  /// Conference path for display (e.g., "tryswift-tokyo-2026")
  public let conferencePath: String
  /// Conference display name (e.g., "try! Swift Tokyo 2026")
  public let conferenceDisplayName: String
  public let title: String
  public let abstract: String
  public let talkDetail: String
  public let talkDuration: TalkDuration
  /// Speaker name at time of submission
  public let speakerName: String
  /// Speaker email at time of submission
  public let speakerEmail: String
  public let bio: String
  public let iconURL: String?
  public let notes: String?
  public let speakerID: UUID
  public let speakerUsername: String
  public let status: ProposalStatus
  public let createdAt: Date?
  public let updatedAt: Date?

  public init(
    id: UUID,
    conferenceId: UUID,
    conferencePath: String,
    conferenceDisplayName: String,
    title: String,
    abstract: String,
    talkDetail: String,
    talkDuration: TalkDuration,
    speakerName: String,
    speakerEmail: String,
    bio: String,
    iconURL: String? = nil,
    notes: String? = nil,
    speakerID: UUID,
    speakerUsername: String,
    status: ProposalStatus = .submitted,
    createdAt: Date? = nil,
    updatedAt: Date? = nil
  ) {
    self.id = id
    self.conferenceId = conferenceId
    self.conferencePath = conferencePath
    self.conferenceDisplayName = conferenceDisplayName
    self.title = title
    self.abstract = abstract
    self.talkDetail = talkDetail
    self.talkDuration = talkDuration
    self.speakerName = speakerName
    self.speakerEmail = speakerEmail
    self.bio = bio
    self.iconURL = iconURL
    self.notes = notes
    self.speakerID = speakerID
    self.speakerUsername = speakerUsername
    self.status = status
    self.createdAt = createdAt
    self.updatedAt = updatedAt
  }
}

/// Request object for creating a new proposal
public struct CreateProposalRequest: Codable, Sendable {
  /// Conference path/alias (e.g., "tryswift-tokyo-2026")
  public let conferencePath: String
  public let title: String
  public let abstract: String
  public let talkDetail: String
  public let talkDuration: TalkDuration
  public let speakerName: String
  public let speakerEmail: String
  public let bio: String
  public let iconURL: String?
  public let notes: String?

  public init(
    conferencePath: String,
    title: String,
    abstract: String,
    talkDetail: String,
    talkDuration: TalkDuration,
    speakerName: String,
    speakerEmail: String,
    bio: String,
    iconURL: String? = nil,
    notes: String? = nil
  ) {
    self.conferencePath = conferencePath
    self.title = title
    self.abstract = abstract
    self.talkDetail = talkDetail
    self.talkDuration = talkDuration
    self.speakerName = speakerName
    self.speakerEmail = speakerEmail
    self.bio = bio
    self.iconURL = iconURL
    self.notes = notes
  }
}

/// Request object for updating an existing proposal
public struct UpdateProposalRequest: Codable, Sendable {
  public let title: String?
  public let abstract: String?
  public let talkDetail: String?
  public let talkDuration: TalkDuration?
  public let speakerName: String?
  public let speakerEmail: String?
  public let bio: String?
  public let iconURL: String?
  public let notes: String?

  public init(
    title: String? = nil,
    abstract: String? = nil,
    talkDetail: String? = nil,
    talkDuration: TalkDuration? = nil,
    speakerName: String? = nil,
    speakerEmail: String? = nil,
    bio: String? = nil,
    iconURL: String? = nil,
    notes: String? = nil
  ) {
    self.title = title
    self.abstract = abstract
    self.talkDetail = talkDetail
    self.talkDuration = talkDuration
    self.speakerName = speakerName
    self.speakerEmail = speakerEmail
    self.bio = bio
    self.iconURL = iconURL
    self.notes = notes
  }
}
