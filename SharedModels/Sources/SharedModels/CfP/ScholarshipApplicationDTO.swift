import Foundation

/// Data Transfer Object for Scholarship Application
/// Shared between Server and clients
public struct ScholarshipApplicationDTO: Codable, Sendable, Equatable, Identifiable {
  public let id: UUID
  public let conferenceId: UUID
  public let conferencePath: String
  public let conferenceDisplayName: String
  public let applicantId: UUID
  public let applicantUsername: String

  // Personal info
  public let email: String
  public let name: String
  public let schoolAndFaculty: String
  public let currentYear: String
  public let portfolio: String?
  public let githubAccount: String?

  // Purpose and preferences
  public let purposes: [String]
  public let languagePreference: String

  // Ticket info
  public let existingTicketInfo: String?
  public let supportType: ScholarshipSupportType

  // Travel and accommodation (optional, only for ticket_and_travel)
  public let travelDetails: TravelDetails?
  public let accommodationDetails: AccommodationDetails?

  // Financial
  public let totalEstimatedCost: Int?
  public let desiredSupportAmount: Int?
  public let selfPaymentInfo: String?

  // Agreements
  public let agreedTravelRegulations: Bool
  public let agreedApplicationConfirmation: Bool
  public let agreedPrivacy: Bool
  public let agreedCodeOfConduct: Bool

  // Additional
  public let additionalComments: String?

  // Review status
  public let status: ScholarshipApplicationStatus
  public let approvedAmount: Int?
  public let organizerNotes: String?

  // Timestamps
  public let createdAt: Date?
  public let updatedAt: Date?

  public init(
    id: UUID,
    conferenceId: UUID,
    conferencePath: String,
    conferenceDisplayName: String,
    applicantId: UUID,
    applicantUsername: String,
    email: String,
    name: String,
    schoolAndFaculty: String,
    currentYear: String,
    portfolio: String? = nil,
    githubAccount: String? = nil,
    purposes: [String],
    languagePreference: String,
    existingTicketInfo: String? = nil,
    supportType: ScholarshipSupportType,
    travelDetails: TravelDetails? = nil,
    accommodationDetails: AccommodationDetails? = nil,
    totalEstimatedCost: Int? = nil,
    desiredSupportAmount: Int? = nil,
    selfPaymentInfo: String? = nil,
    agreedTravelRegulations: Bool,
    agreedApplicationConfirmation: Bool,
    agreedPrivacy: Bool,
    agreedCodeOfConduct: Bool,
    additionalComments: String? = nil,
    status: ScholarshipApplicationStatus = .submitted,
    approvedAmount: Int? = nil,
    organizerNotes: String? = nil,
    createdAt: Date? = nil,
    updatedAt: Date? = nil
  ) {
    self.id = id
    self.conferenceId = conferenceId
    self.conferencePath = conferencePath
    self.conferenceDisplayName = conferenceDisplayName
    self.applicantId = applicantId
    self.applicantUsername = applicantUsername
    self.email = email
    self.name = name
    self.schoolAndFaculty = schoolAndFaculty
    self.currentYear = currentYear
    self.portfolio = portfolio
    self.githubAccount = githubAccount
    self.purposes = purposes
    self.languagePreference = languagePreference
    self.existingTicketInfo = existingTicketInfo
    self.supportType = supportType
    self.travelDetails = travelDetails
    self.accommodationDetails = accommodationDetails
    self.totalEstimatedCost = totalEstimatedCost
    self.desiredSupportAmount = desiredSupportAmount
    self.selfPaymentInfo = selfPaymentInfo
    self.agreedTravelRegulations = agreedTravelRegulations
    self.agreedApplicationConfirmation = agreedApplicationConfirmation
    self.agreedPrivacy = agreedPrivacy
    self.agreedCodeOfConduct = agreedCodeOfConduct
    self.additionalComments = additionalComments
    self.status = status
    self.approvedAmount = approvedAmount
    self.organizerNotes = organizerNotes
    self.createdAt = createdAt
    self.updatedAt = updatedAt
  }
}
