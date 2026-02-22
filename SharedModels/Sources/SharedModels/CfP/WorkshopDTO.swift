import Foundation

/// Workshop-specific details stored as JSON alongside a proposal
public struct WorkshopDetails: Codable, Sendable, Equatable {
  public let language: WorkshopLanguage
  public let numberOfTutors: Int
  public let keyTakeaways: String
  public let prerequisites: String?
  public let agendaSchedule: String
  public let participantRequirements: String
  public let requiredSoftware: String?
  public let networkRequirements: String
  public let requiredFacilities: [FacilityRequirement]
  public let facilityOther: String?
  public let motivation: String
  public let uniqueness: String
  public let potentialRisks: String?

  public init(
    language: WorkshopLanguage,
    numberOfTutors: Int,
    keyTakeaways: String,
    prerequisites: String? = nil,
    agendaSchedule: String,
    participantRequirements: String,
    requiredSoftware: String? = nil,
    networkRequirements: String,
    requiredFacilities: [FacilityRequirement] = [],
    facilityOther: String? = nil,
    motivation: String,
    uniqueness: String,
    potentialRisks: String? = nil
  ) {
    self.language = language
    self.numberOfTutors = numberOfTutors
    self.keyTakeaways = keyTakeaways
    self.prerequisites = prerequisites
    self.agendaSchedule = agendaSchedule
    self.participantRequirements = participantRequirements
    self.requiredSoftware = requiredSoftware
    self.networkRequirements = networkRequirements
    self.requiredFacilities = requiredFacilities
    self.facilityOther = facilityOther
    self.motivation = motivation
    self.uniqueness = uniqueness
    self.potentialRisks = potentialRisks
  }
}

/// Language used in the workshop
public enum WorkshopLanguage: String, Codable, Sendable, Equatable, CaseIterable {
  case english
  case japanese
  case bilingual
  case other

  public var displayName: String {
    switch self {
    case .english: return "English"
    case .japanese: return "Japanese / 日本語"
    case .bilingual: return "Bilingual / バイリンガル"
    case .other: return "Other"
    }
  }
}

/// Facility/equipment requirements for workshops
public enum FacilityRequirement: String, Codable, Sendable, Equatable, CaseIterable {
  case projector
  case microphone
  case whiteboard
  case powerStrips = "power_strips"

  public var displayName: String {
    switch self {
    case .projector: return "Projector"
    case .microphone: return "Microphone"
    case .whiteboard: return "Whiteboard"
    case .powerStrips: return "Power Strips"
    }
  }
}

/// Co-instructor details for workshop proposals
public struct CoInstructor: Codable, Sendable, Equatable {
  public let name: String
  public let email: String
  public let sns: String?
  public let githubUsername: String
  public let bio: String
  public let iconURL: String?

  public init(
    name: String,
    email: String,
    sns: String? = nil,
    githubUsername: String,
    bio: String,
    iconURL: String? = nil
  ) {
    self.name = name
    self.email = email
    self.sns = sns
    self.githubUsername = githubUsername
    self.bio = bio
    self.iconURL = iconURL
  }
}
